{
  config,
  lib,
  n9,
  inputs,
  ...
}:

let
  cfg = config.n9.users;
in
{
  imports = [ inputs.home-manager.darwinModules.default ];

  # TODO: A generic mkHome function?
  options.home-manager.users = lib.mkOption {
    type = lib.types.attrsOf (
      lib.types.submoduleWith {
        specialArgs = { inherit n9 inputs; };
        modules = [
          # special
          (
            { name, ... }:
            {
              config._module.args.userName = name;
            }
          )

          # modules
          # none-now

          # configs
          ../../home/essential.nix
          ../home-essential.nix
        ];
      }
    );
  };

  config = lib.mkIf (cfg != { }) {
    assertions = [
      {
        assertion = (lib.length (lib.attrNames cfg)) == 1;
        message = "darwin currently cannot have multiple user defined!";
      }
    ];

    users.users = lib.mapAttrs (userName: _: {
      name = userName;
      home = "/Users/${userName}";
    }) cfg;

    system.primaryUser = lib.elemAt (lib.attrNames cfg) 0;
  };
}
