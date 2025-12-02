{
  config,
  lib,
  ...
}:

let
  # This config will get referenced in the final system.build stage, currently
  # only nixos reads it, other oses is just for deducing the hostPlatform.
  cfg = config.hardware.configuration;
in
{
  # sudo nixos-generate-config --no-filesystems --show-hardware-config > hardware-configuration.nix
  options.hardware.configuration = lib.mkOption {
    type = lib.types.nullOr lib.types.pathInStore;
    default = null;
    apply = v: if v == null then { } else v;
  };

  # We can, try to detect the hostPlatform from hardware-configuration.nix:
  config.nixpkgs.hostPlatform =
    let
      args = {
        config.hardware.enableRedistributableFirmwware = false;
        lib.mkDefault = lib.id;
        pkgs = null;
        modulesPath = null;
      };
      hostPlatform = (if lib.isPath cfg then import cfg args else { }).nixpkgs.hostPlatform or null;
    in
    lib.mkIf (cfg != null && hostPlatform != null) hostPlatform;
}
