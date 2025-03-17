{
  config,
  lib,
  n9,
  hostName,
  ...
}:

let
  cfg = config.n9.network;
in
{
  options.n9.network = {
    domain = lib.mkOption {
      type = lib.types.str;
      default = "y.xas.is";
    };

    # networkd + nat, mostly v4, v6 may have some issues...
    router = {
      # act as enable as well:
      lan = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
      };

      # cidr address, of local:
      address = lib.mkOption {
        type = lib.types.str;
      };

      # TODO: Calculate in nix? Seems quite hard as math lib is missing...
      range = {
        from = lib.mkOption { type = lib.types.str; };
        to = lib.mkOption { type = lib.types.str; };
        mask = lib.mkOption { type = lib.types.str; };
      };

      wan = lib.mkOption {
        type = lib.types.str;
      };
    };
  };

  config = lib.mkIf (cfg.router.lan != null) {
    systemd.network.enable = true;

    # Don't like the resolved...
    services.resolved.enable = false;

    systemd.network.networks."66-${cfg.router.lan}" = n9.mkCarrierOnlyNetwork cfg.router.lan {
      networkConfig = {
        Address = cfg.router.address;
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
    };

    # Don't try to resolve the LAN if NetworkManager is enabled:
    networking.networkmanager.unmanaged = lib.mkIf config.networking.networkmanager.enable [
      "interface-name:${cfg.router.lan}"
    ];

    # And don't try to wake online if NetworkManager is enabled:
    systemd.network.wait-online.enable = !config.networking.networkmanager.enable;

    # https://wiki.archlinux.org/title/Dnsmasq
    services.dnsmasq =
      let
        range = cfg.router.range;
        address = lib.elemAt (lib.splitString "/" cfg.router.address) 0;
      in
      {
        enable = true;
        settings = {
          interface = [ cfg.router.lan ];
          bind-dynamic = true;
          cache-size = "10000";
          enable-ra = true;

          dhcp-authoritative = true;
          dhcp-option = [
            "1,${range.mask}"
            "3,${address}" # gateway
            "6,${address}" # dns
          ];
          dhcp-range = [
            "${range.from},${range.to},72h"
            "::,constructor:${cfg.router.wan},slaac,ra-stateless,ra-names,72h"
          ];

          inherit (cfg) domain;
          local = "/${cfg.domain}/"; # only resolve in local, don't go out
          address = [ "/${hostName}.${cfg.domain}/${address}" ];
        };
      };

    # NAT + Firewall with nftables.
    # @see nixpkgs/nixos/modules/services/networking/nat-nftables.nix)
    # nix eval --raw ".#nixosConfigurations.rout.config.networking.nftables.tables"
    networking.nftables.enable = true;

    networking.nat = {
      enable = true;
      enableIPv6 = true;
      internalInterfaces = [ cfg.router.lan ];
      externalInterface = cfg.router.wan;
    };

    networking.firewall.allowedUDPPorts = [
      53 # DNS
      67 # DHCP
    ];

    # The `networking.firewall.filterForward = true` is conflicted, and has no
    # such customization options. TODO: How to make one?
    # https://github.com/LostAttractor/Router/blob/master/configuration/network/nftables.nix
    networking.nftables.tables."mss-clamping" = {
      family = "inet";
      content = ''
        chain forward {
          type filter hook forward priority filter; policy accept;
          tcp flags syn tcp option maxseg size set rt mtu
        }
      '';
    };
  };
}
