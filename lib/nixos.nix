{
  self,
  nixpkgs,
  home-manager,
  colmena,
  ...
}@args: # <- Flake inputs

# Make NixOS, with disk, bootloader, networking, hostname, etc.
# Switched from `nixosSystem` to `colmenaHive`, for my own flaver (the colmena
# has both remote and local deployment, which is quite nice).
# TODO: Revert using `nixosSystem` when there's no deployment?
#
# @input that: Flake `self` of the modules.
# @input hostName: The name you're.
# @input bulk: For bulk mode, users should call makeHive themselves.
# @input modules: To nixosSystem.
# @input packages: Shortcut.
# @input deployment: Where you want to deploy?
#
# @output: AttrSet of ${hostName} of ${that}.
#
# Notice, the deployment.keys are uploaded, it means it can't survive next
# reboot if you're using the default option to upload to /run/keys.
that: hostName: system: # <- Module arguments

{
  bulk ? false,
  modules,
  packages ? [ ],
  deployment ? { },
}: # <- NixOS `nixosSystem {}` (Hmm, not really)

let
  inherit (self.lib) utils;
  inherit (nixpkgs) lib;

  nodeNixpkgs = nixpkgs.legacyPackages.${system};
  hostId = builtins.substring 63 8 (builtins.hashString "sha512" hostName);
  hasHome = that ? homeConfigurations;
  homeConfig = that.homeConfigurations.${hostName};

  combined = nixpkgs.lib.recursiveUpdate {
    allowLocalDeployment = true;
    keys = lib.optionalAttrs hasHome (
      lib.fold (a: b: a.deployment.keys // b) { } (lib.attrValues homeConfig)
    );
  } deployment;
in
{
  # For home.nix, n9 requires one-to-one configuration, can only have 1 host:
  passthru = {
    # inherit system;
    inherit hostName;
  };
}
// (if !bulk then colmena.lib.makeHive else lib.id) {
  meta = {
    nixpkgs = nodeNixpkgs;
    nodeNixpkgs.${hostName} = nodeNixpkgs;
  };

  ${hostName} = {
    imports =
      [
        (import ../pkgs/nixpkgs.nix args)
        (
          { pkgs, ... }:
          {
            nix.settings = {
              experimental-features = [
                "nix-command"
                "flakes"
              ];
              substituters = [ "https://mirrors.ustc.edu.cn/nix-channels/store" ];
            };

            boot.loader = {
              systemd-boot.enable = true;
              efi.canTouchEfiVariables = true;
            };

            # For default networking, using NixOS's default (dhcpcd).
            networking = {
              inherit hostName hostId;
            };

            environment = {
              sessionVariables.NIX_CRATES_INDEX = "sparse+https://mirrors.ustc.edu.cn/crates.io-index/";

              systemPackages =
                with pkgs;
                [
                  gnumake
                  git
                ]
                ++ (map (utils.attrByIfStringPath pkgs) packages);
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

            # TODO: To other places.
            networking = {
              firewall.allowedTCPPorts = [ 22 ];
              firewall.allowedUDPPorts = [ ];
            };

            services.openssh = {
              enable = true;
              ports = [ 22 ];
            };
          }
        )

        home-manager.nixosModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
        }
      ]
      ++ (lib.optionals hasHome (
        (lib.mapAttrsToList (
          username:
          {
            user,
            group,
            config,
            ...
          }:
          args:
          assert lib.assertMsg (username != "root") "can't manage root!";
          {
            users = {
              groups.${username} = group;
              users.${username} = user;
            };

            home-manager.users.${username} = config;
          }
        ) homeConfig)
        ++ [
          {
            users.users.root.hashedPassword = "!";
          }
        ]
      ))
      ++ modules;

    deployment = combined;
  };
}
