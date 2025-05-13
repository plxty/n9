{ n9, inputs, ... }:

whereHosts:

# For reverting to nixosSystem, commit 0dfc786daefb441c8e14b3f97fa3393847d1de9d
let
  inherit (inputs.nixpkgs) lib;

  # Wow, is it a really config?
  cfg = config.n9.os;

  # Fetch nixpkgs.hostPlatform for system, it's a fake import as well:
  # TODO: Multiple hosts, should use ${hostName}?
  hwModule = "${whereHosts}/hardware-configuration.nix";
  system =
    (import hwModule {
      config.hardware.enableRedistributableFirmware = null;
      inherit lib;
      pkgs = null;
      modulesPath = "";
    }).nixpkgs.hostPlatform.content;

  # Feed the colmena:
  apply =
    hostName: modules:
    let
      system' = lib.trace "nixos: selecting ${system} for ${hostName}" system;
    in
    {
      meta.nodeNixpkgs.${hostName} = n9.mkPkgs system';
      meta.nodeSpecialArgs.${hostName} = {
        inherit hostName;
        userName = null; # make some "generic" modules working
        osConfig = cfg.${hostName};
      };

      ${hostName} = n9.recursiveMerge [
        {
          imports = [
            # options
            ./nixos/config/disk.nix
            ./nixos/config/network.nix
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
          apply = lib.mapAttrsToList apply;
        };
      }
      whereHosts
    ];
  };

  inherit (modules) config;
in
cfg
