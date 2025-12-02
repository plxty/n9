{ config, lib, ... }:

let
  cfg = config.networking.bridge;
in
{
  options.networking.bridge = lib.mkOption {
    type = lib.types.attrsOf (
      lib.types.submodule {
        options.slaves = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ ];
        };

        # TODO: Separate for different slaves?
        options.extraConfig = lib.mkOption {
          type = lib.types.attrs;
          default = { };
        };
      }
    );
    default = { };
  };

  # TODO: variant.nixos.networking.bridges?
  config.variant.nixos.systemd.network.netdevs = lib.concatMapAttrs (n: v: {
    "33-${n}".netdevConfig = {
      Kind = "bridge";
      Name = n;
    };
  }) cfg;

  config.variant.nixos.systemd.network.networks = lib.concatMapAttrs (
    master: v:
    lib.mergeAttrsList (
      lib.map (slave: {
        "33-${master}-${slave}" = lib.recursiveUpdate {
          matchConfig.Name = slave;
          networkConfig = {
            Bridge = master;
            DHCP = "no";
            LinkLocalAddressing = "no";
          };
          linkConfig.RequiredForOnline = "enslaved";
        } v.extraConfig;
      }) v.slaves
    )
  ) cfg;
}
