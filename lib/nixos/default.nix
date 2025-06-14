{ n9, lib, ... }@args:

type: whereHosts:

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
      specialArgs = {
        inherit hostName;
        userName = null; # make some "generic" modules working
        osConfig = cfg.${hostName};
      };
    in
    if type == "linux" then
      {
        meta.nodeNixpkgs.${hostName} = n9.mkPkgs system';
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
      }
    else if type == "darwin" then
      {
        # suit for darwinSystem argument, TODO: move to lib/darwin/default.nix?
        ${hostName} = n9.recursiveMerge [
          {
            specialArgs = args // specialArgs;

            modules = [
              # nix-darwin (macos) modules
              ../generic/config/users.nix
              ../darwin/config/users.nix

              # configs
              hwModule
              ../generic/essential.nix
              ../darwin/essential.nix
            ];
          }
        ];
      }
    else
      abort "unsupported os type";

  modules = lib.evalModules {
    modules = [
      {
        # funny: n9.os.evil.n9.users.byte.n9.security.keys
        # The unspecified type will produce a [] (seems like?).
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
