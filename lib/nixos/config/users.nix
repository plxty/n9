{
  options,
  config,
  lib,
  pkgs, # MUST have, maybe the module system is using `functionArgs`?
  n9,
  ...
}@args:
let
  cfg = config.n9.users;
in
{
  # @see https://nixos-and-flakes.thiscute.world/other-usage-of-flakes/module-system
  imports = [
    n9.inputs.home-manager.nixosModules.home-manager
  ];

  options.n9.users = lib.mkOption {
    type = lib.types.attrsOf (
      lib.types.submodule (
        { name, ... }:
        {
          options.modules = lib.mkOption {
            # use options.home-manager here will cause inifite recursion...
            type = lib.types.listOf lib.types.anything;
            default = [ ];
            apply =
              raw:
              let
                mkAttrsOption = lib.mkOption {
                  type = lib.types.attrs;
                  default = { };
                };

                eval = lib.evalModules {
                  modules = [
                    {
                      # Fake type here, types will be valided when exposed to
                      # top-level, by home-manager itself.
                      options.home = mkAttrsOption;
                      options.programs = mkAttrsOption;
                      options.services = mkAttrsOption;

                      # N9, expose to n9.users, because we won't export it to
                      # the toplevel, therefore the check MUST be done within
                      # the home modules, so there the options.
                      options.n9 = lib.removeAttrs options.n9 [ "users" ];
                    }
                    ../../home/essential.nix
                  ] ++ raw;
                  class = "n9";
                  specialArgs = args // {
                    n9 = n9 // {
                      userName = name;
                    };
                  };
                };

                cfg = eval.config;
              in
              {
                users.groups.${name}.gid = null;
                users.users.${name} = {
                  isNormalUser = true;
                  uid = null;
                  group = name;
                  extraGroups = [ "wheel" ];
                };

                # Expose to top-level with mkMergeTopLevel:
                home-manager.users.${name} = lib.removeAttrs cfg [ "n9" ];

                # Expose to other moduels only, access via mkUsers:
                inherit (cfg) n9;
              };
          };
        }
      )
    );
  };

  # For config that MUST expose to other places, it can be placed here.
  # e.g. the n9.users.xxx is accssible by all times, therefore no need to
  # place it to the toplevel.
  # And you MUST avoid expose the n9.users, because options.n9.users is the
  # thing of config.n9.users, leading to infinite recursion.
  config = n9.lib.mkMergeTopLevel [ "home-manager" "users" ] (
    (lib.optional (cfg != { }) {
      # https://discourse.nixos.org/t/users-users-name-packages-vs-home-manager-packages/22240/2
      home-manager.useUserPackages = true;
      home-manager.useGlobalPkgs = true;

      # disable root for security:
      users.users.root.hashedPassword = "!";
    })
    ++ lib.mapAttrsToList (_: v: v.modules) cfg
  );
}
