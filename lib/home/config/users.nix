{
  options,
  config,
  pkgs,
  lib,
  n9,
  inputs,
  ...
}:

let
  # Notice, we're in toplevel, this is the only toplevel config that controls
  # home-manager, because we have too much combinations of it:
  # * nixos + home-manager
  # * darwin + home-manager
  # * home-manager (standalone, currently won't support)
  # Therefore we make the platform specific config here, TODO: is it good?
  cfg = config.n9.users;
in
{
  # FIXME: Identify the standalone version, how?
  imports = [
    inputs.home-manager.${if pkgs.stdenv.isLinux then "nixosModules" else "darwinModules"}.default
  ];

  options.home-manager.users = lib.mkOption {
    type = lib.types.attrsOf (
      lib.types.submoduleWith {
        # We also place the pkgs here, as what lib/darwin/default.nix explains.
        specialArgs = { inherit pkgs n9 inputs; };
        modules =
          [
            (
              { name, ... }:
              {
                config._module.args.userName = name;
              }
            )
            ../../shared/config/essentials.nix
            ./essentials.nix
            { n9.essentials.shared.enable = false; } # FIXME: Standalone should set
            ./fish.nix
            ./helix.nix
          ]
          ++ lib.optionals pkgs.stdenv.isLinux [
            ../../shared/config/keys.nix
            ./passwd.nix
            ./ssh-key.nix
            ./gnome
            ./boxes.nix
          ];
      }
    );
  };

  # To have our own namespace :) And to avoid potential inifinite recursion :(
  options.n9.users = options.home-manager.users;

  config = lib.mkIf (cfg != { }) (
    lib.mkMerge [
      {
        # https://discourse.nixos.org/t/users-users-name-packages-vs-home-manager-packages/22240/2
        home-manager.useUserPackages = true;
        home-manager.useGlobalPkgs = true;

        # We can access the "raw" definition values within options.definitions,
        # thus avoiding to have all the default configurations (like doRename).
        home-manager.users = lib.mkAliasDefinitions options.n9.users;
      }

      (lib.optionalAttrs pkgs.stdenv.isLinux {
        users.groups = lib.mapAttrs (_: _: { }) cfg;
        users.users = lib.mapAttrs (userName: _: {
          isNormalUser = lib.mkDefault true;
          group = userName;
          extraGroups = [ "wheel" ];
        }) cfg;
      })

      (lib.optionalAttrs pkgs.stdenv.isDarwin {
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
      })
    ]
  );
}
