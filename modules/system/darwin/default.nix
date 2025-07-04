{
  pkgs,
  ...
}@args:

{
  config = {
    # Make home-manager's fish work, for iterm2 use '/run/current-system/sw/bin/fish' shell.
    programs.fish.enable = true;

    # TODO: Merge with @see lib/nixos/config/gnome.nix
    # Nerd fonts can be installed by iterm2.
    fonts.packages = with pkgs; [
      jetbrains-mono
      source-code-pro
    ];

    # Appearence of macOS:
    system.defaults.dock = {
      mineffect = "scale";
      autohide = true;
    };

    # TODO: Use flake's nixpkgs for consistency.
    nixpkgs.overlays = [ (import ../../../pkgs/overlay.nix args) ];

    # For the ~/Applications issues:
    # https://github.com/nix-darwin/nix-darwin/commit/fbe795f39dbcc242ddc6f7ab01689617746d9402
    # https://github.com/nix-community/home-manager/issues/1341

    system.defaults.CustomSystemPreferences = {
      # https://github.com/runjuu/InputSourcePro/issues/24#issuecomment-2978745464
      "/Library/Preferences/FeatureFlags/Domain/UIKit.plist" = {
        redesigned_text_cursor.Enabled = false;
      };
    };

    # TODO: Merge with @see sshd.nix
    deployment.allowLocalDeployment = true;

    system.stateVersion = 6;
  };
}
