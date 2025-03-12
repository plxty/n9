{
  config,
  lib,
  pkgs,
  self,
  ...
}:

let
  cfg = config.n9.environment.gnome;
  dconf = import ../dconf-gnome.nix { inherit lib; };
in
{
  options.n9.environment.gnome = {
    enable = lib.mkEnableOption "gnome";
  };

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      dconf-editor
      dconf2nix
    ];

    programs.gnome-shell = {
      enable = true;
      extensions = with pkgs.gnomeExtensions; [
        { package = brightness-control-using-ddcutil; }
        { package = switcher; }
        { package = self.inputs.paperwm.packages.${pkgs.system}.default; }
        { package = dash-to-dock; }
        { package = customize-ibus; }
      ];
    };

    # Force xdg to be non-unicode directories, just using defaults:
    xdg.userDirs.enable = true;

    inherit (dconf) dconf;
  };
}
