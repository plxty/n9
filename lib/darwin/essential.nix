{ ... }:

{
  # Make home-manager's fish work, for iterm2 use '/run/current-system/sw/bin/fish' shell.
  programs.fish.enable = true;

  # Appearence of macOS:
  system.defaults.dock = {
    mineffect = "scale";
    autohide = true;
  };

  # For the ~/Applications issues:
  # https://github.com/nix-darwin/nix-darwin/commit/fbe795f39dbcc242ddc6f7ab01689617746d9402
  # https://github.com/nix-community/home-manager/issues/1341

  system.stateVersion = 6;
}
