{
  config,
  lib,
  pkgs,
  n9,
  this,
  ...
}:

let
  cfg = config.n9.environment.gnome;
  usercfg = n9.users "gnome" (v: v.n9.environment.gnome) config;

  dconf = import ./dconf.nix { inherit lib; };
  ext = package: { inherit package; };
in
{
  options = lib.optionalAttrs (this ? usersModule) {
    n9.environment.gnome = {
      enable = lib.mkEnableOption "gnome";
      swapCtrlCaps = lib.mkOption {
        type = lib.types.bool;
        default = false;
      };
    };
  };

  config =
    if (this ? usersModule) then
      lib.mkIf cfg.enable (
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
      )
    else
      n9.mkIfUsers (v: v.enable) usercfg {
        services = {
          xserver = {
            enable = true;
            displayManager.gdm.enable = true;
            desktopManager.gnome.enable = true;
            excludePackages = [ pkgs.xterm ];
          };

          # @see nixpkgs/nixos/modules/services/x11/desktop-managers/gnome.md
          gnome.core-apps.enable = false;
        };

        environment = {
          # HiDPI:
          sessionVariables = {
            NIXOS_OZONE_WL = "1";
            QT_AUTO_SCREEN_SCALE_FACTOR = "1";
            QT_ENABLE_HIGHDPI_SCALING = "1";
          };

          systemPackages = with pkgs; [
            pop-wallpapers
            wl-clipboard
            (brave.override (prev: {
              commandLineArgs = builtins.concatStringsSep " " [
                (prev.commandLineArgs or "")
                "--wayland-text-input-version=3"
                "--sync-url=https://brave-sync.pteno.cn/"
              ];
            }))
            ptyxis
            nautilus
            gedit
            gnome-tweaks
            file-roller
          ];

          gnome.excludePackages = with pkgs; [
            gnome-backgrounds
            gnome-tour
            gnome-shell-extensions
          ];
        };

        # https://wiki.nixos.org/wiki/Fonts
        fonts = {
          enableDefaultPackages = true;
          packages = with pkgs; [
            # Main fonts:
            noto-fonts
            noto-fonts-cjk-sans
            noto-fonts-cjk-serif

            # +-*/{}=[]:
            jetbrains-mono
            source-code-pro
            nerd-fonts.symbols-only

            # Extra fonts:
            wqy_microhei
            wqy_zenhei
          ];

          # gnome-font-viewer
          fontconfig.defaultFonts = {
            serif = [ "Noto Serif CJK SC" ];
            sansSerif = [ "Noto Sans CJK SC" ];
            monospace = [ "Noto Sans Mono CJK SC" ];
          };
        };

        i18n.inputMethod = {
          enable = true;
          type = "ibus";
          ibus.engines = with pkgs.ibus-engines; [
            rime
            libpinyin
          ];
        };

        # For I2C control of ddcutil:
        hardware.i2c.enable = true;
        users.users = lib.mapAttrs (_: v: lib.mkIf v.enable { extraGroups = [ "i2c" ]; }) usercfg;
      };
}
