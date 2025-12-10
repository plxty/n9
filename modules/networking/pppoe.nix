{
  config,
  lib,
  n9,
  pkgs,
  ...
}:

let
  cfg = config.networking.pppoe;
in
{
  options.networking.pppoe = lib.mkOption {
    type = lib.types.attrsOf (
      lib.types.submodule {
        options.name = lib.mkOption {
          type = lib.types.str;
          default = "wan";
        };

        options.nic = lib.mkOption {
          type = lib.types.str;
        };
      }
    );
    default = { };
  };

  config.security.keys = lib.mkIf (cfg != { }) {
    # FIXME: Multiple pppoe instance...
    "/etc/ppp/keys/wan".source = "wan";
  };

  config.variant.nixos = lib.mkIf (cfg != { }) {
    boot.kernelModules = [
      "pppoe"
    ];

    # PPPoE (netdev), networkd managed as well:
    networking.useDHCP = false;
    networking.dhcpcd.enable = false;

    services.pppd = {
      enable = true;
      # https://man7.org/linux/man-pages/man8/pppd.8.html
      peers = lib.mapAttrs (n: v: {
        config = ''
          plugin pppoe.so
          ifname ${n}
          nic-${v.nic}
          file /etc/ppp/keys/wan

          persist
          maxfail 0
          holdoff 10

          +ipv6 ipv6cp-use-ipaddr
          defaultroute
          usepeerdns
          noipdefault
        '';
      }) cfg;
    };

    # Upstream DNS from pppoe:
    services.dnsmasq.settings.resolv-file = "/run/pppd/resolv.conf";
  };
}
