{
  config,
  lib,
  inputs,
  ...
}:

{
  imports = [ inputs.colmena.nixosModules.deploymentOptions ];

  options.deployment = {
    profileWide = lib.mkOption {
      type = lib.types.str;
      default = "/nix/var/nix/profiles/system"; # nixos && nix-darwin
    };

    profileCurrent = lib.mkOption {
      type = lib.types.str;
      default = "/run/current-system";
    };

    activateScript = lib.mkOption {
      type = lib.types.str;
      default = "bin/switch-to-configuration"; # nixos
    };

    switchGoal = lib.mkOption {
      type = lib.types.nullOr (lib.types.listOf lib.types.str);
      default = null;
    };

    rootAbsolute = lib.mkOption {
      type = lib.types.str;
      default = import ../../lib/dir.nix;
    };
  };

  config.deployment = lib.mkMerge [
    (lib.mkIf config.variant.is.home-manager {
      privilegeEscalationCommand = [ ];
      targetUser = config.variant.home-manager.home.username;

      # For home-manager, we should use a different directory to make colmena works:
      profileWide = "${config.variant.home-manager.home.homeDirectory}/.local/state/nix/profiles/home-manager";
      activateScript = "activate";
      switchGoal = [
        "--driver-version"
        "1"
      ];
    })

    (lib.mkIf config.variant.is.nix-darwin {
      activateScript = "activate";
      switchGoal = [ ];
    })
  ];
}
