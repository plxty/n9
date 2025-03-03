{
  options,
  config,
  lib,
  pkgs, # MUST have, maybe the module system is using `functionArgs`?
  home-manager,
  ...
}@args:
let
  cfg = config.n9.users;

  # https://gist.github.com/udf/4d9301bdc02ab38439fd64fbda06ea43
  # Must make the config "static", i.e. the fields must be known by nix,
  # for example `config = genAttrs` will cause inifinte recursion, while
  # `config = { services = ... }` will work.
  # This might because the module's `options` is "part of" the `config`
  # argument, therefore accessing config is like holding a big lock with
  # options, which we're still defininig.
  #
  # The mkMergeTopLevel requires a "static" configuration as well, that
  # is the inner configurations MUST contains the given toplevel attrs.
  # There's currently no way to make it dynamic here.
  # TODO: When there's no users defined, the function will error.
  mkMergeTopLevel =
    names: attrs:
    lib.getAttrs names (lib.mapAttrs (k: lib.mkMerge) (lib.foldAttrs (n: a: [ n ] ++ a) [ ] attrs));
in
{
  # @see https://nixos-and-flakes.thiscute.world/other-usage-of-flakes/module-system
  imports = [
    home-manager.nixosModules.home-manager
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
                    userName = name;
                  };
                };
              in
              eval.config;
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
  config = mkMergeTopLevel [ "home-manager" "users" ] (
    (lib.optional (cfg != { }) {
      # https://discourse.nixos.org/t/users-users-name-packages-vs-home-manager-packages/22240/2
      home-manager.useUserPackages = true;
      home-manager.useGlobalPkgs = true;

      # disable root for security:
      users.users.root.hashedPassword = "!";
    })
    ++ lib.mapAttrsToList (userName: v: {

      users.groups.${userName}.gid = null;
      users.users.${userName} = {
        isNormalUser = true;
        uid = null;
        group = userName;
        extraGroups = [ "wheel" ];
      };

      # Expose to top-level with mkMergeTopLevel:
      home-manager.users.${userName} = lib.removeAttrs v.modules [ "n9" ];
    }) cfg
  );
}
