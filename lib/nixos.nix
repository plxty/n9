{ nixpkgs, ... }:

hosts:

# For reverting to nixosSystem, commit 0dfc786daefb441c8e14b3f97fa3393847d1de9d
let
  inherit (nixpkgs) lib;

  # Feed the colmena:
  apply =
    hostName: modules:
    let
      # Fetch nixpkgs.hostPlatform for system, it's a fake import as well:
      hwModule = "${hosts}/hardware-configuration.nix";
      hwConfig = import hwModule {
        config.hardware.enableRedistributableFirmware = null;
        inherit lib;
        pkgs = null;
        modulesPath = "";
      };

      system = hwConfig.nixpkgs.hostPlatform.content;
      system' = lib.trace "selecting ${system} for ${hostName}" system;
    in
    {
      meta.nodeNixpkgs.${hostName} = nixpkgs.legacyPackages.${system'};
      meta.nodeSpecialArgs.${hostName} = { inherit hostName; };

      ${hostName}.imports = [
        # options
        ./nixos/config/disk.nix
        ./nixos/config/sshd.nix
        ./nixos/config/users.nix
        ./generic/config/keys.nix
        ./nixos/config/keys.nix
        ./nixos/config/passwd.nix
        ./nixos/config/ssh-key.nix
        ./nixos/config/gnome.nix
        ./nixos/config/boxes.nix

        # configs
        ./nixos/essential.nix
        hwModule
      ] ++ modules;
    };

  inherit
    (lib.evalModules {
      modules = [
        {
          options.n9.os = lib.mkOption {
            type = lib.types.attrsOf (
              lib.types.submodule (
                { name, ... }:
                {
                  # FIXME: The imports are "fake" here, to keep user level API
                  # "consistency", archiving a real system option is hard.
                  options.imports = lib.mkOption {
                    type = lib.types.listOf lib.types.unspecified;
                    apply = apply name;
                  };
                }
              )
            );
          };
        }

        # Top level, here we are!
        hosts
      ];
      class = "n9.os";
    })
    config
    ;
in
lib.mapAttrsToList (_: v: v.imports) config.n9.os
