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

  fwClash = "0xfeedc1a5";

  firstName = attrs: lib.elemAt (lib.attrNames attrs) 0;
  flatMapAttrsToList = fn: attrs: lib.flatten (lib.mapAttrsToList fn attrs);

  # Only IPv4 for now...
  clashIPs' = [
    "198.18.0.0/15" # Fake-ip
  ]
  ++ lib.splitString "\n" (lib.readFile "${n9.sources.geoip}/text/google.txt");
  clashIPs = lib.concatStringsSep "," (lib.filter (lib.hasInfix ".") clashIPs');
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

    # TODO: Move out router?
    clash.enable = lib.mkEnableOption "clash";
  };

  config.variant.nixos =
    let
      networkManageEnabled = config.variant.nixos.networking.networkmanager.enable;
    in
    lib.mkMerge [
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
              "interface:${n},::,constructor:${firstName cfg.wan},slaac,ra-stateless,ra-names,72h"
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

        # NAT + Firewall with nftables.
        # @see nixpkgs/nixos/modules/services/networking/nat-nftables.nix)
        # nix eval --raw ".#nixosConfigurations.rout.config.networking.nftables.tables"
        networking.nftables.enable = true;
        networking.nftables.flushRuleset = true;

        networking.nat = {
          enable = true;
          enableIPv6 = true;
          internalInterfaces = lib.attrNames cfg.lan;
          externalInterface = firstName cfg.wan;
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

        # Relavents:
        # TODO: Make clash service part of dnsmasq?
        services.networkd-dispatcher = {
          enable = true;
          rules."restart-resolve" =
            let
              lan = lib.attrNames cfg.lan;
            in
            {
              onState = [ "routable" ];
              script = ''
                #!${pkgs.runtimeShell}

                # shellcheck disable=SC2154
                if [[ "$AdministrativeState" != "configured" ]]; then
                  exit 0
                fi

                # shellcheck disable=SC2154
                case "$IFACE" in
                "${firstName cfg.wan}")
                  systemctl restart dnsmasq ${lib.optionalString cfg.clash.enable "mihomo"}
                  ;;
                ${lib.optionalString ((lib.length lan) != 0) ''
                  ${lib.concatMapStringsSep "|" (s: ''"${s}"'') lan})
                    systemctl restart dnsmasq
                    ;;
                ''}
                esac

                exit 0
              '';
            };
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

        # Auto-configuration disabled, due to restriction to amytelecom (they
        # disabled the auto updates...), therefore we can only update manually.
        # Revert via e18d423308a8b70c7311403d33dc36c98981c05b
        environment.systemPackages = with pkgs; [
          curl # dependencies...
          (writers.writePython3Bin "clash-renew" {
            libraries = [ python3Packages.pyyaml ];
            doCheck = false;
          } ./clash-renew.py)
        ];
      })

      (lib.mkIf (cfg.clash.enable && cfg.lan != { }) {
        boot.kernelModules = [
          "nft_socket"
          "nft_tproxy"
        ];

        # The policy route is mandatory, because tproxy won't stop nf hooks and it
        # won't change the packet, the `ip_forward` can hard to tell where to route
        # the packet, we need to tell it routing to lo device, and there's mihomo.
        systemd.network.networks."99-clash" = {
          matchConfig.Name = "lo";
          networkConfig = {
            DHCP = "no";
            LinkLocalAddressing = "no";
          };
          linkConfig.RequiredForOnline = "carrier";
          routes = [
            {
              Table = 100; # any of it, 42, 101, ..., just need to match below
              Destination = "0.0.0.0/0";
              Type = "local";
            }
            {
              Destination = "198.18.0.0/15"; # router should be proxied as well :)
              Type = "local";
            }
          ];
          routingPolicyRules = [
            {
              FirewallMark = fwClash;
              Table = 100;
              Priority = 100;
            }
          ];
        };

        # Make dnsmasq forward:
        services.dnsmasq.settings = {
          server = lib.mkBefore [
            "127.0.0.1#1053"
          ];
          strict-order = true;
        };

        # https://github.com/Seidko/my-linux-note/blob/master/tproxy%20with%20clash%20and%20nftables.md
        # Trace packet with `meta nftrace set 1`, monitor with shell `nft monitor trace`.
        networking.nftables.tables.clash = {
          family = "inet";
          content = ''
            set clash_proxy {
              typeof ip daddr
              flags interval
              auto-merge
              elements = {${clashIPs}}
            }

            chain prerouting {
              type filter hook prerouting priority mangle;
              ip daddr @clash_proxy meta l4proto { tcp, udp } mark set ${fwClash} \
                tproxy ip to 127.0.0.1:7892 counter meta nftrace set 1
            }
          '';
        };

        networking.firewall = {
          # To forward tproxy traffic to lo, nf doesn't support something like always-accept.
          extraReversePathFilterRules = "meta mark ${fwClash} accept";
          extraInputRules = "meta mark ${fwClash} accept";
        };
      })
    ];
}
