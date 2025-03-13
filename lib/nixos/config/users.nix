{
  options,
  config,
  lib,
  n9,
  inputs,
  hostName,
  ...
}:
let
  cfg = config.n9.users;
in
{
  # @see https://nixos-and-flakes.thiscute.world/other-usage-of-flakes/module-system
  imports = [ inputs.home-manager.nixosModules.default ];

  # Of home-manager, it will evalModules twice, but we can have a nice look.
  # The submoduleWith can handle the merge of options (nixpkgs/lib/types.nix):
  options.home-manager.users = lib.mkOption {
    type = lib.types.attrsOf (
      lib.types.submoduleWith {
        specialArgs = { inherit n9 inputs hostName; };
        modules = [
          # special
          (
            { name, ... }:
            {
              config._module.args.userName = name;
            }
          )

          # options
          ../../generic/config/keys.nix
          ../../home/config/passwd.nix
          ../../home/config/ssh-key.nix
          ../../home/config/gnome.nix
          ../../home/config/boxes.nix

          # configs
          ../../home/essential.nix
        ];
      }
    );
  };

  # To have our own namespace :) And to avoid potential inifinite recursion :(
  options.n9.users = options.home-manager.users;

  config = lib.mkMerge [
    (lib.mkIf (cfg != { }) {
      # https://discourse.nixos.org/t/users-users-name-packages-vs-home-manager-packages/22240/2
      home-manager.useUserPackages = true;
      home-manager.useGlobalPkgs = true;
    })

    {
      users.groups = lib.mapAttrs (_: _: { gid = null; }) cfg;
      users.users = lib.mapAttrs (userName: _: {
        isNormalUser = true;
        uid = null;
        group = userName;
        extraGroups = [ "wheel" ];
      }) cfg;

      # We can access the "raw" definition values within options.definitions,
      # thus avoiding to have all the default configurations (like doRename).
      home-manager.users = lib.mkAliasDefinitions options.n9.users;
    }
  ];
}
