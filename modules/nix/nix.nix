{
  config,
  lib,
  n9,
  pkgs,
  inputs,
  ...
}:

let
  cfg = config.nix.nix;

  inherit ((import ../../flake.nix).nixConfig) substituters;
in
{
  options.nix.nix = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
    };
  };

  options.users = n9.mkAttrsOfSubmoduleOption {
    config.deployment.file.".local/share/nix/trusted-settings.json" = lib.mkIf cfg.enable {
      text = ''
        {
          "substituters": { "${lib.concatStringsSep " " substituters}": true }
        }
      '';
      force = true;
    };
  };

  config.variant = lib.mkIf cfg.enable (
    lib.mkMerge [
      (lib.genAttrs [ "nixos" "nix-darwin" "home-manager" ] (_: {
        nix.settings = {
          experimental-features = [
            "nix-command"
            "flakes"
          ];
          inherit substituters;
        };

        nix.extraOptions = ''
          keep-outputs = true
          keep-derivations = true
        '';

        nix.registry = {
          # nix develop n9#qemu
          n9.to = {
            type = "path";
            path = config.deployment.rootAbsolute; # save some debug times
          };
        };

        # Using the flake version of nixpkgs:
        nix.nixPath = [
          "nixpkgs=${inputs.nixpkgs}"
          # "nixpkgs-overlays=${../../pkgs}" # WIP, can't really work without `inputs`
          "/nix/var/nix/profiles/per-user/root/channels" # neccessary?
        ];

        # https://nixos.wiki/wiki/Storage_optimization
        nix.gc = {
          automatic = true;
          options = "--delete-older-than 29d";
        };
      }))

      rec {
        nixos.nix.optimise.automatic = true;
        nix-darwin = nixos;
      }

      {
        nixos.nix.gc = {
          dates = "weekly";
          randomizedDelaySec = "3h";
        };
        home-manager.nix.package = pkgs.nix;
      }
    ]
  );
}
