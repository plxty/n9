{ n9, ... }@args:

let
  fn =
    {
      hostName,
      specialArgs,
      hwModule,
      modules,
      ...
    }:
    {
      # suit for darwinSystem argument, TODO: better way? make home?
      ${hostName} = n9.recursiveMerge [
        {
          specialArgs = args // specialArgs;

          modules = [
            # nix-darwin (macos) modules
            ../generic/config/users.nix
            ./config/users.nix

            # configs
            hwModule
            ../generic/essential.nix
            ./essential.nix
            modules
          ];
        }
      ];
    };
in
import ../generic args fn
