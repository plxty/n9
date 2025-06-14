{ n9, ... }@args:

let
  fn =
    {
      hostName,
      system,
      specialArgs,
      hwModule,
      modules,
    }:
    {
      meta.nodeNixpkgs.${hostName} = n9.mkPkgs system;
      meta.nodeSpecialArgs.${hostName} = specialArgs;

      ${hostName} = n9.recursiveMerge [
        {
          imports = [
            # nixos (linux) modules
            ./config/disk.nix
            ./config/network.nix
            ./config/sshd.nix
            ../generic/config/users.nix
            ./config/users.nix
            ../generic/config/keys.nix
            ./config/keys.nix
            ./config/passwd.nix
            ./config/ssh-key.nix
            ./config/gnome.nix
            ./config/boxes.nix

            # configs
            hwModule
            ../generic/essential.nix
            ./essential.nix
          ];
        }
        modules
      ];
    };
in
import ../generic args fn
