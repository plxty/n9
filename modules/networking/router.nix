{
  name,
  config,
  lib,
  n9,
  pkgs,
  ...
}:

let
  cfg = config.networking.router;

  flatMapAttrsToList = fn: attrs: lib.flatten (lib.mapAttrsToList fn attrs);
in
{
  # networkd + nat, mostly v4, v6 may have some issues...
  options.networking.router = {
    domain = lib.mkOption {
      type = lib.types.str;
      default = "xas.is";
    };

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

    # TODO: Only one wan is actually being used.
    wan = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submodule {
          options.extraConfig = lib.mkOption {
            type = lib.types.attrs;
            default = { };
          };
        }
      );
    };
  };

  config.variant.nixos =
    let
      networkManageEnabled = config.variant.nixos.networking.networkmanager.enable;
    in
    (lib.mkIf (cfg.lan != { }) {
      systemd.network.enable = true;
      networking.useNetworkd = true;

      # Don't like the resolved...
      services.resolved.enable = false;

      systemd.network.networks =
        (lib.concatMapAttrs (n: v: {
          "66-${n}" = lib.recursiveUpdate {
            matchConfig.Name = n;
            networkConfig = {
              Address = v.address;
              IPv6SendRA = "yes";
              IPv6AcceptRA = "no";
              DHCP = "no";
              DHCPPrefixDelegation = "yes";
              LinkLocalAddressing = "ipv6";
            };
            ipv6SendRAConfig = {
              Managed = "yes";
              OtherInformation = "yes";
            };
            dhcpPrefixDelegationConfig.Token = "::1";
            linkConfig.RequiredForOnline = "carrier";
          } v.extraConfig;
        }) cfg.lan)
        // (lib.concatMapAttrs (n: v: {
          "66-${n}" = lib.recursiveUpdate {
            matchConfig.Name = n;
            networkConfig = {
              DHCP = "yes";
              LinkLocalAddressing = "ipv6";
            };
            # https://wiki.debian.org/IPv6PrefixDelegation
            dhcpV6Config = {
              PrefixDelegationHint = "::/64"; # TODO: configurable?
              WithoutRA = "solicit";
              UseDNS = "no";
              UseHostname = "no";
            };
          } v.extraConfig;
        }) cfg.wan);

      # Don't try to resolve the LAN if NetworkManager is enabled:
      networking.networkmanager.unmanaged = lib.mapAttrsToList (n: _: "interface-name:${n}") cfg.lan;

      # And don't try to wake online if NetworkManager is enabled:
      systemd.network.wait-online.enable = !networkManageEnabled;

      # https://wiki.archlinux.org/title/Dnsmasq
      services.dnsmasq = {
        enable = true;
        settings = {
          interface = (lib.attrNames cfg.lan) ++ [ "lo" ];
          bind-dynamic = true;
          cache-size = "10000";
          enable-ra = true;
          server = [
            "223.5.5.5"
            "119.29.29.29"
          ];

          dhcp-authoritative = true;
          dhcp-option = flatMapAttrsToList (
            n: v:
            let
              address = lib.elemAt (lib.splitString "/" v.address) 0;
            in
            [
              "interface:${n},1,${v.range.mask}"
              "interface:${n},3,${address}" # gateway
              "interface:${n},6,${address}" # dns
            ]
          ) cfg.lan;

          dhcp-range = flatMapAttrsToList (n: v: [
            "interface:${n},${v.range.from},${v.range.to},72h"
            "interface:${n},::,constructor:${n9.firstName cfg.wan},slaac,ra-stateless,ra-names,72h"
          ]) cfg.lan;

          inherit (cfg) domain;
          local = "/${cfg.domain}/"; # only resolve in local, don't go out
          address = lib.mapAttrsToList (
            _: v:
            let
              address = lib.elemAt (lib.splitString "/" v.address) 0;
            in
            "/${name}.${cfg.domain}/${address}"
          ) cfg.lan;
        };
      };

      services.networkd-dispatcher = {
        enable = true;
        rules."restart-resolve" = {
          onState = [ "routable" ];
          script = ''
            #!${pkgs.runtimeShell}

            # shellcheck disable=SC2154
            if [[ "$AdministrativeState" != "configured" ]]; then
              exit 0
            fi

            # shellcheck disable=SC2154
            case "$IFACE" in
            "${n9.firstName cfg.wan}")
              systemctl restart dnsmasq
              ;;
            ${lib.optionalString (cfg.lan != { }) ''
              ${lib.concatMapStringsSep "|" (s: ''"${s}"'') (lib.attrNames cfg.lan)})
                systemctl restart dnsmasq
                ;;
            ''}
            esac

            exit 0
          '';
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
        internalInterfaces = lib.attrNames cfg.lan;
        externalInterface = n9.firstName cfg.wan;
      };

      # Allow everything comes in LAN, we're intranet, ain't we?
      # For WAN, we still needs strong control :/
      networking.firewall.trustedInterfaces = lib.attrNames cfg.lan;

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
    });
}
