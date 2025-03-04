{ nixpkgs, ... }:

file:

# For reverting to nixosSystem, commit 0dfc786daefb441c8e14b3f97fa3393847d1de9d
let
  inherit (nixpkgs) lib;

  # Feed the colmena:
  apply = hostName: system: modules: {
    meta.nodeNixpkgs.${hostName} = nixpkgs.legacyPackages.${system};
    meta.nodeSpecialArgs.${hostName} = { inherit hostName; };

    ${hostName}.imports = [
      # options
      ./nixos/config/disk.nix
      ./nixos/config/sshd.nix
      ./nixos/config/users.nix
      ./nixos/config/secrets.nix
      ./nixos/config/passwd.nix
      ./nixos/config/pop-shell.nix
      ./nixos/config/boxes.nix

      # configs
      ./nixos/essential.nix
    ] ++ modules;
  };

  inherit
    (lib.evalModules {
      modules = [
        {
          options.n9.os = lib.mkOption {
            type = lib.types.attrsOf (
              lib.types.submodule (
                { config, name, ... }:
                {
                  options.system = lib.mkOption {
                    type = lib.types.str;
                  };

                  options.modules = lib.mkOption {
                    type = lib.types.listOf lib.types.unspecified;
                    apply = apply name config.system;
                  };

                  config.system = lib.mkDefault "x86_64-linux";
                }
              )
            );
          };
        }

        # Top level, here we are!
        file
      ];
      class = "n9.os";
    })
    config
    ;
in
lib.mapAttrsToList (_: v: v.modules) config.n9.os
