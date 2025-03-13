{ nixpkgs, self, ... }@inputs:

whereHosts:

# For reverting to nixosSystem, commit 0dfc786daefb441c8e14b3f97fa3393847d1de9d
let
  inherit (nixpkgs) lib;

  # Feed the colmena:
  apply =
    hostName: modules:
    let
      # Fetch nixpkgs.hostPlatform for system, it's a fake import as well:
      # TODO: Multiple hosts, should use ${hostName}?
      hwModule = "${whereHosts}/hardware-configuration.nix";
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
      meta.nodeSpecialArgs.${hostName} = (lib.removeAttrs inputs [ "nixpkgs" ]) // {
        inherit hostName;
        userName = null; # make some "generic" modules working
        osConfig = config;
      };

      ${hostName} = self.lib.recursiveMerge [
        {
          imports = [
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
            hwModule
            ./nixos/essential.nix
          ];
        }

        modules
      ];
    };

  modules = lib.evalModules {
    modules = [
      {
        # funny: n9.os.evil.n9.users.byte.n9.security.keys
        options.n9.os = lib.mkOption {
          type = lib.types.unspecified;
          apply = hosts: lib.fold lib.recursiveUpdate { } (lib.mapAttrsToList apply hosts);
        };
      }

      # Top level, here we are!
      whereHosts
    ];
  };

  inherit (modules) config;
in
config.n9.os
