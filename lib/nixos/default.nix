{ n9, lib, ... }:

whereHosts:

# For reverting to nixosSystem, commit 0dfc786daefb441c8e14b3f97fa3393847d1de9d
let
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
            # modules
            ./config/disk.nix
            ./config/network.nix
            ./config/sshd.nix
            ./config/users.nix
            ../generic/config/keys.nix
            ./config/keys.nix
            ./config/passwd.nix
            ./config/ssh-key.nix
            ./config/gnome.nix
            ./config/boxes.nix

            # configs
            hwModule
            ./essential.nix
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
