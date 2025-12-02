{
  config,
  lib,
  n9,
  inputs,
  ...
}:

let
  cfg = config.nix.nixpkgs;
in
{
  # To provide pkgs in modules argument:
  imports = [ "${inputs.nixpkgs}/nixos/modules/misc/nixpkgs.nix" ];

  options.nix.nixpkgs.enable = lib.mkOption {
    type = lib.types.bool;
    default = true;
  };

  options.users = n9.mkAttrsOfSubmoduleOption {
    config.deployment.file.".config/nixpkgs/config.nix".text = lib.mkIf cfg.enable ''
      { allowUnfree = true; }
    '';
  };

  # OSes will use the overrided `pkgs` with those options set:
  config.nixpkgs = lib.mkIf cfg.enable {
    # Make overlay everywhere.
    overlays = [
      (import ../../pkgs/overlays.nix { inherit inputs; })
    ];

    # Unfree is acceptable, what's the price?
    config.allowUnfree = true;
  };
}
