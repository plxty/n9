{
  config,
  lib,
  n9,
  pkgs,
  ...
}:

let
  cfg = config.networking.clash;
  wan = n9.firstName config.networking.router.wan;
  lan = lib.attrNames config.networking.router.lan;

  fwClash = "0xfeedc1a5";

  # Only IPv4 for now...
  clashIPs' = [
    "198.18.0.0/15" # Fake-ip
  ]
  ++ lib.splitString "\n" (lib.readFile "${n9.sources.geoip}/text/google.txt");
  clashIPs = lib.concatStringsSep "," (lib.filter (lib.hasInfix ".") clashIPs');
in
{
  options.networking.clash.enable = lib.mkEnableOption "clash";

  config.variant.nixos = lib.mkMerge [
    (lib.mkIf cfg.enable {
      # Old new world, things should be redirect by yourself (including DNS or
      # HTTPS proxy, depending on the clash-renew.py):
      services.mihomo = {
        enable = true;
        package = pkgs.mihomo-unstable;
        configFile = "/etc/mihomo/clash.yaml";
        webui = pkgs.metacubexd;
        tunMode = true; # tproxy needs it as well
      };
    })

    # Setup global proxy:
    (lib.mkIf (cfg.enable && (lib.length lan) != 0) {
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

      # TODO: Make clash service part of dnsmasq when restarting?
      services.networkd-dispatcher = {
        enable = true;
        rules."restart-mihomo" = {
          onState = [ "routable" ];
          script = ''
            #!${pkgs.runtimeShell}

            # shellcheck disable=SC2154
            if [[ "$AdministrativeState" == "configured" && "$IFACE" == "${wan}" ]]; then
              systemctl restart mihomo
            fi

            exit 0
          '';
        };
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

  # Auto-configuration disabled, due to restriction to amytelecom (they
  # disabled the auto updates...), therefore we can only update manually.
  config.environment.packages = lib.mkIf cfg.enable (
    with pkgs;
    [
      curl # dependencies...
      (writers.writePython3Bin "clash-renew" {
        libraries = [ python3Packages.pyyaml ];
        doCheck = false;
      } ./clash-renew.py)
    ]
  );

  # TODO: Clean way?
  config.system.activation.post = lib.mkIf cfg.enable ''
    mihomo_data=/var/lib/private/mihomo
    mkdir -p $mihomo_data
    chown nobody:nogroup $mihomo_data
    ln -Tsf "${n9.sources.v2ray-rules-geoip}" $mihomo_data/GeoIP.dat
    ln -Tsf "${n9.sources.v2ray-rules-geosite}" $mihomo_data/GeoSite.dat
  '';
}
