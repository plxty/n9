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
      default =
        if config.variant.is.home-manager then
          # For home-manager, we should use a different directory to make colmena works:
          "${config.variant.home-manager.home.homeDirectory}/.local/state/nix/profiles/home-manager"
        else
          "/nix/var/nix/profiles/system";
    };

    profileCurrent = lib.mkOption {
      type = lib.types.str;
      default = "/run/current-system";
    };

    rootAbsolute = lib.mkOption {
      type = lib.types.str;
      default = import ../../lib/dir.nix;
    };
  };

  config.deployment = lib.mkIf config.variant.is.home-manager {
    privilegeEscalationCommand = [ ];
    targetUser = config.variant.home-manager.home.username;
  };
}
