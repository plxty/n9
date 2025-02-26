{
  self,
  nixpkgs,
  colmena,
  home-manager,
  ...
}@inputs: # <- Flake inputs

# Make NixOS, with disk, bootloader, networking, hostname, etc.
node: hostName: system: modules:

let
  inherit (nixpkgs) lib;

  # FIXME
  hasHome = node ? homeConfigurations;
  homeConfig = node.homeConfigurations.${hostName};
in

lib.nixosSystem {
  inherit system;

  modules =
    [
      ../pkgs/nixpkgs.nix
      {
        nix.settings = {
          experimental-features = [
            "nix-command"
            "flakes"
          ];
          # TODO: Try merging with flake.nix::nixConfig? If mismatched,
          # substituers in flake.nix but not in nix.settings will be
          # considered as untrusted, making warnings.
          substituters = [
            "https://mirror.sjtu.edu.cn/nix-channels/store"
            "https://mirrors.ustc.edu.cn/nix-channels/store"
            "https://mirrors.sustech.edu.cn/nix-channels/store"
          ];
        };

        # https://nixos.wiki/wiki/Storage_optimization
        nix.optimise.automatic = true;
        nix.gc = {
          automatic = true;
          dates = "weekly";
          options = "--delete-older-than 29d";
          randomizedDelaySec = "3h";
        };

        boot.loader = {
          systemd-boot.enable = true;
          efi.canTouchEfiVariables = true;
        };

        # For default networking, using NixOS's default (dhcpcd).
        networking = {
          inherit hostName;
          hostId = builtins.substring 63 8 (builtins.hashString "sha512" hostName);
        };

        environment = {
          sessionVariables.NIX_CRATES_INDEX = "sparse+https://mirrors.ustc.edu.cn/crates.io-index/";
          # systemPackages = map (utils.attrByIfStringPath pkgs) packages;
        };

        time.timeZone = "Asia/Shanghai";
        i18n.defaultLocale = "zh_CN.UTF-8";

        virtualisation = {
          containers.enable = true;
          podman = {
            enable = true;
            defaultNetwork.settings.dns_enabled = true;
          };
        };

        system.stateVersion = "25.05";
      }
    ]
    # ++ (lib.optionals (deployment ? nixKey) [
    #   # nix key generate-secret --key-name dotfiles.rockwolf.eu-X > .nix-key
    #   # cat .nix-key | nix key convert-secret-to-public
    #   { nix.settings.trusted-public-keys = [ deployment.nixKey ]; }
    # ])
    ++ (lib.optionals hasHome (
      (lib.flatten (lib.mapAttrsToList (_: v: v.modules) homeConfig))
      ++ [ { users.users.root.hashedPassword = "!"; } ]
    ))
    ++ modules;

  specialArgs.n9 = {
    inherit node hostName inputs;
    inherit (self) lib;
  };

  # TODO: Split out home-manager only, for darwin or else platform:
  extraModules = [
    colmena.nixosModules.deploymentOptions
    ../nixos/disk
    ../nixos/miscell/sshd.nix
    (
      { config, lib, ... }:
      let
        hmModule = home-manager.nixosModules.home-manager;
      in
      {
        imports = [ hmModule ];

        options.home = lib.mkOption {
          type = lib.types.attrsOf (
            lib.types.submodule {
              options.enable = lib.mkOption {
                type = lib.types.bool;
                default = true;
              };

              options.modules = lib.types.listsOf (
                lib.types.submodule {
                  # inherit to home-manager:
                  inherit (hmModule.options) home programs;
                }
              );
            }
          );
        };

        config = {
          # https://discourse.nixos.org/t/users-users-name-packages-vs-home-manager-packages/22240/2
          home-manager.useUserPackages = true;
          home-manager.useGlobalPkgs = true;
        };
      }
    )
  ];
}
