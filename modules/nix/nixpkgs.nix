{ n9, inputs, ... }:

{
  # To provide pkgs in modules argument:
  imports = [ "${inputs.nixpkgs}/nixos/modules/misc/nixpkgs.nix" ];

  options.users = n9.mkAttrsOfSubmoduleOption { } {
    config.deployment.file.".config/nixpkgs/config.nix".text = ''
      { allowUnfree = true; }
    '';
  };

  # OSes will use the overrided `pkgs` with those options set:
  config.nixpkgs = {
    # Make overlay everywhere.
    overlays = [
      (import ../../pkgs/overlays.nix { inherit inputs; })
    ];

    # Unfree is acceptable, what's the price?
    config.allowUnfree = true;
  };
}
