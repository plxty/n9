{
  options,
  config,
  lib,
  pkgs, # MUST have, maybe the module system is using `functionArgs`?
  self,
  home-manager,
  ...
}@args:
let
  cfg = config.n9.users;

  # @see attrs = mkOptionType { ... }
  mkAttrsOption = lib.mkOption {
    type = lib.types.attrs // {
      merge = _: defs: self.lib.recursiveMerge (lib.map (def: def.value) defs);
    };
    default = { };
  };

  # Evaluate here to prevent infinite recursion, what we want is to "customize"
  # the home-manager so that we can define some system options within users.
  # Kind of "ugly", but it works for now, it costs me too much efforts...
  apply =
    userName: modules:
    (lib.evalModules {
      modules = [
        {
          # Fake type here, types will be valided when exposed to
          # top-level, by home-manager itself.
          # Using home-manager's options directly is kind of difficult, it's
          # hard to keep consistency of home-manager and ours users states.
          options.home = mkAttrsOption;
          options.programs = mkAttrsOption;
          options.services = mkAttrsOption;

          # N9, expose to n9.users, options check MUST be done within users:
          options.n9 = lib.removeAttrs options.n9 [ "users" ];
        }
        ../../home/essential.nix
      ] ++ modules;
      class = "n9.users";
      specialArgs = args // {
        inherit userName;
      };
    }).config;
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
          # In here, we can avoid touching `config.home-manager`, because many
          # of modules are trying to define options within `config.home-manager`,
          # and that will cause infinite loop.
          options.modules = lib.mkOption {
            type = lib.types.listOf lib.types.unspecified;
            default = [ ];
            apply = apply name;
          };
        }
      )
    );
  };

  config = lib.mkMerge [
    (lib.mkIf (cfg != { }) {
      # disable root for security:
      users.users.root.hashedPassword = "!";

      # https://discourse.nixos.org/t/users-users-name-packages-vs-home-manager-packages/22240/2
      home-manager.useUserPackages = true;
      home-manager.useGlobalPkgs = true;
    })

    {
      users.groups = lib.mapAttrs (userName: _: { gid = null; }) cfg;
      users.users = lib.mapAttrs (userName: _: {
        isNormalUser = true;
        uid = null;
        group = userName;
        extraGroups = [ "wheel" ];
      }) cfg;

      home-manager.users = lib.mapAttrs (userName: v: lib.removeAttrs v.modules [ "n9" ]) cfg;
    }
  ];
}
