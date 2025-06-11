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
  ext = package: { inherit package; };
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
            (ext brightness-control-using-ddcutil)
            (ext (
              # to compat with gnome 48, should be removed if it's merged
              n9.patch switcher (
                pkgs.fetchurl {
                  url = "https://patch-diff.githubusercontent.com/raw/daniellandau/switcher/pull/177.patch";
                  hash = "sha256-VzLv4DuI+I2RruZdC2SD+W+j/sin0S7SJjitrfNoA7s=";
                }
              )
            ))
            (ext (n9.patch paperwm "paperwm-focus"))
            (ext dash-to-dock)
            (ext (n9.patch customize-ibus "customize-ibus-keep"))
            (ext tray-icons-reloaded)
            (ext hide-cursor)
            (ext focus)
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
