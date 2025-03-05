{
  config,
  lib,
  pkgs,
  self,
  home-manager,
  ...
}:
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
  # TODO: Place some user configurations to n9.users.xxx.yyy other than modules?
  apply =
    userName: modules:
    (lib.evalModules {
      modules = [
        # options
        {
          options = {
            # Using home-manager's options directly is kind of difficult, it's
            # hard to keep consistency of home-manager and ours users states.
            home = mkAttrsOption;
            programs = mkAttrsOption;
            services = mkAttrsOption;
            dconf = mkAttrsOption;
          };
        }
        ../../common/config/secrets.nix
        ../../home/config/passwd.nix
        ../../home/config/ssh-key.nix
        ../../home/config/pop-shell.nix
        ../../home/config/boxes.nix

        # configs
        ../../home/essential.nix
      ] ++ modules;
      class = "n9.users";
      specialArgs = {
        inherit pkgs self userName;
        lib = lib // {
          hm = import "${home-manager}/modules/lib" { inherit lib; };
        };
        osConfig = config;
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
          options.imports = lib.mkOption {
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

      home-manager.users = lib.mapAttrs (userName: v: lib.removeAttrs v.imports [ "n9" ]) cfg;
    }
  ];
}
