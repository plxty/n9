{
  config,
  lib,
  n9,
  pkgs,
  ...
}:

let
  cfg = config.n9.network;
in
{
  options.n9.network = {
    domain = lib.mkOption {
      type = lib.types.str;
      default = "hut.pen.guru"; # or igloo?
    };

    # networkd + nat, mostly v4, v6 may have some issues...
    router = {
      lan = lib.mkOption {
        type = lib.types.attrsOf (
          lib.types.submodule {
            # cidr address, of local:
            options.address = lib.mkOption {
              type = lib.types.str;
            };

            # TODO: Calculate in nix? Seems quite hard as math lib is missing...
            options.range = {
              from = lib.mkOption { type = lib.types.str; };
              to = lib.mkOption { type = lib.types.str; };
              mask = lib.mkOption { type = lib.types.str; };
            };

            options.extraConfig = lib.mkOption {
              type = lib.types.attrs;
              default = { };
            };
          }
        );
        default = { };
      };

      wan = lib.mkOption {
        type = lib.types.attrsOf (
          lib.types.submodule {
            options.enable = lib.mkEnableOption "wan";
          }
        );
        apply =
          v:
          let
            names = lib.attrNames (lib.filterAttrs (_: v: v.enable) v);
          in
          assert lib.assertMsg ((lib.length names) == 1) "only one wan is supported!";
          lib.elemAt names 0;
      };
    };

    clash = {
      enable = lib.mkEnableOption "clash";

      subscribe = lib.mkOption {
        type = lib.types.str;
        default = "subscribe";
      };
    };
  };

  config = lib.mkMerge [
    (lib.mkIf (cfg.router.lan != { }) {
      systemd.network.enable = true;

      # Don't like the resolved...
      services.resolved.enable = false;

      systemd.network.networks = lib.concatMapAttrs (n: v: {
        "66-${n}" = lib.recursiveUpdate (n9.mkCarrierOnlyNetwork n {
          networkConfig = {
            Address = v.address;
            IPv6SendRA = "yes";
            IPv6AcceptRA = "no";
            DHCPPrefixDelegation = "yes";
            LinkLocalAddressing = "ipv6";
          };
          ipv6SendRAConfig = {
            Managed = "yes";
            OtherInformation = "yes";
          };
          dhcpPrefixDelegationConfig.Token = "::1";
        }) v.extraConfig;
      }) cfg.router.lan;

      # Don't try to resolve the LAN if NetworkManager is enabled:
      networking.networkmanager.unmanaged = lib.mkIf config.networking.networkmanager.enable (
        lib.mapAttrsToList (n: _: "interface-name:${n}") cfg.router.lan
      );

      # And don't try to wake online if NetworkManager is enabled:
      systemd.network.wait-online.enable = !config.networking.networkmanager.enable;

      # https://wiki.archlinux.org/title/Dnsmasq
      services.dnsmasq = {
        enable = true;
        settings = {
          interface = lib.attrNames cfg.router.lan;
          bind-dynamic = true;
          cache-size = "10000";
          enable-ra = true;

          dhcp-authoritative = true;
          dhcp-option = n9.flatMapAttrsToList (
            n: v:
            let
              address = lib.elemAt (lib.splitString "/" v.address) 0;
            in
            [
              "interface:${n},1,${v.range.mask}"
              "interface:${n},3,${address}" # gateway
              "interface:${n},6,${address}" # dns
            ]
          ) cfg.router.lan;

          dhcp-range = n9.flatMapAttrsToList (n: v: [
            "interface:${n},${v.range.from},${v.range.to},72h"
            "interface:${n},::,constructor:${cfg.router.wan},slaac,ra-stateless,ra-names,72h"
          ]) cfg.router.lan;

          inherit (cfg) domain;
          local = "/${cfg.domain}/"; # only resolve in local, don't go out
          address = lib.mapAttrsToList (
            _: v:
            let
              address = lib.elemAt (lib.splitString "/" v.address) 0;
            in
            "/${config.networking.hostName}.${cfg.domain}/${address}"
          ) cfg.router.lan;
        };
      };

      # NAT + Firewall with nftables.
      # @see nixpkgs/nixos/modules/services/networking/nat-nftables.nix)
      # nix eval --raw ".#nixosConfigurations.rout.config.networking.nftables.tables"
      networking.nftables.enable = true;
      networking.nftables.flushRuleset = true;

      networking.nat = {
        enable = true;
        enableIPv6 = true;
        internalInterfaces = lib.attrNames cfg.router.lan;
        externalInterface = cfg.router.wan;
      };

      networking.firewall.interfaces = lib.mapAttrs (_: _: {
        allowedUDPPorts = [
          53 # DNS
          67 # DHCP
        ];
      }) cfg.router.lan;

      # The `networking.firewall.filterForward = true` is conflicted, and has no
      # such customization options. TODO: How to make one?
      # https://github.com/LostAttractor/Router/blob/master/configuration/network/nftables.nix
      networking.nftables.tables.mss-clamping = {
        family = "inet";
        content = ''
          chain forward {
            type filter hook forward priority filter; policy accept;
            tcp flags syn tcp option maxseg size set rt mtu
          }
        '';
      };
    })

    (lib.mkIf cfg.clash.enable {
      # Old new world, things should be redirect by yourself (including DNS or
      # HTTPS proxy, depending on the clash-renew.py):
      services.mihomo = {
        enable = true;
        package = n9.patch pkgs.mihomo "mihomo-taste";
        configFile = "/etc/mihomo/clash.yaml";
        webui = pkgs.metacubexd;
        tunMode = true; # tproxy needs it as well
      };

      # The subscribe path:
      n9.security.keys."/etc/mihomo/subscribe".source = cfg.clash.subscribe;

      # https://github.com/NixOS/nixpkgs/blob/26d499fc9f1d567283d5d56fcf367edd815dba1d/nixos/modules/system/boot/systemd.nix#L747C1-L748C1
      systemd.services.clash-renew = {
        requires = [ "network-online.target" ];
        after = [ "network-online.target" ];
        path = with pkgs; [
          (python3.withPackages (py3: [ py3.pyyaml ]))
          curl
        ];
        serviceConfig =
          let
            dir = lib.fileset.toSource {
              root = ./.;
              fileset = ./clash-renew.py;
            };
          in
          {
            Type = "oneshot";
            ExecStart = "${dir}/clash-renew.py";
          };
      };

      # Make mihomo depends:
      systemd.services.mihomo = {
        requires = [ "clash-renew.service" ];
        after = [ "clash-renew.service" ];
        startAt = "Mon,Tue,Thu,Sat *-*-* 05:06:07";
      };
    })
  ];
}
