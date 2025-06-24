{ config, lib, ... }@args:

let
  cfg = config.n9.essentials.darwin;
in
{
  options.n9.essentials.darwin.enable = lib.mkOption {
    type = lib.types.bool;
    default = true;
  };

  config = lib.mkIf cfg.enable {
    # Make home-manager's fish work, for iterm2 use '/run/current-system/sw/bin/fish' shell.
    programs.fish.enable = true;

    # Appearence of macOS:
    system.defaults.dock = {
      mineffect = "scale";
      autohide = true;
    };

    # TODO: @see lib/nixos/config/essentials.nix
    nix.optimise.automatic = true;

    # TODO: Use flake's nixpkgs for consistency.
    nixpkgs.overlays = [ (import ../../../pkgs/overlay.nix args) ];

    # For the ~/Applications issues:
    # https://github.com/nix-darwin/nix-darwin/commit/fbe795f39dbcc242ddc6f7ab01689617746d9402
    # https://github.com/nix-community/home-manager/issues/1341

    system.stateVersion = 6;
  };
}
