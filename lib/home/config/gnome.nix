{
  config,
  lib,
  pkgs,
  n9,
  ...
}:

let
  cfg = config.n9.environment.gnome;
  dconf = import ../dconf-gnome.nix { inherit lib; };
in
{
  options.n9.environment.gnome = {
    enable = lib.mkEnableOption "gnome";
    swapCtrlCaps = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
  };

  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      {
        home.packages = with pkgs; [
          dconf-editor
          dconf2nix
        ];

        programs.gnome-shell = {
          enable = true;
          extensions = with pkgs.gnomeExtensions; [
            { package = brightness-control-using-ddcutil; }
            { package = switcher; }
            { package = n9.patch paperwm "paperwm-focus"; }
            { package = dash-to-dock; }
            { package = n9.patch customize-ibus "customize-ibus-keep"; }
            { package = tray-icons-reloaded; }
            { package = hide-cursor; }
          ];
        };

        # Force xdg to be non-unicode directories, just using defaults:
        xdg.userDirs.enable = true;

        inherit (dconf) dconf;
      }

      {
        dconf.settings."org/gnome/desktop/input-sources".xkb-options = [
          "terminate:ctrl_alt_bksp"
          "lv3:menu_switch"
        ];
      }

      (lib.mkIf cfg.swapCtrlCaps {
        dconf.settings."org/gnome/desktop/input-sources".xkb-options = [ "ctrl:swapcaps" ];
      })
    ]
  );
}
