{
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
        specialArgs = {
          inherit
            n9
            inputs
            hostName
            ;
        };
        modules = [
          # special
          (
            { name, ... }:
            {
              config._module.args.userName = name;
            }
          )

          # modules
          ../../generic/config/keys.nix
          ../../home/config/passwd.nix
          ../../home/config/ssh-key.nix
          ../../home/config/gnome.nix
          ../../home/config/boxes.nix

          # configs
          ../../home/essential.nix
          ../home-essential.nix
        ];
      }
    );
  };

  config = lib.mkIf (cfg != { }) {
    users.groups = lib.mapAttrs (_: _: { }) cfg;
    users.users = lib.mapAttrs (userName: _: {
      isNormalUser = lib.mkDefault true;
      group = userName;
      extraGroups = [ "wheel" ];
    }) cfg;
  };
}
