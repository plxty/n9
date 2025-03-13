{
  config,
  lib,
  pkgs,
  n9,
  ...
}:

let
  # @see lib/home/config/gnome.nix
  usercfg = n9.users "gnome" (v: v.n9.environment.gnome) config;
in
{
  config = lib.mkMerge [
    (n9.mkIfUsers (v: v.enable) usercfg {
      services = {
        xserver = {
          enable = true;
          displayManager.gdm.enable = true;
          desktopManager.gnome.enable = true;
          excludePackages = [ pkgs.xterm ];
        };

        # @see nixpkgs/nixos/modules/services/x11/desktop-managers/gnome.md
        gnome.core-utilities.enable = false;
      };

      environment = {
        # HiDPI:
        sessionVariables = {
          NIXOS_OZONE_WL = "1";
          QT_AUTO_SCREEN_SCALE_FACTOR = "1";
          QT_ENABLE_HIGHDPI_SCALING = "1";
        };

        systemPackages = with pkgs; [
          wl-clipboard
          brave
          ptyxis
          nautilus
          gedit
          gnome-tweaks
        ];

        gnome.excludePackages = with pkgs; [
          gnome-tour
          gnome-shell-extensions
        ];
      };

      fonts.packages = with pkgs; [
        noto-fonts
        noto-fonts-cjk-sans
        noto-fonts-cjk-serif
        noto-fonts-emoji
        wqy_microhei
        wqy_zenhei
        sarasa-gothic
        nerd-fonts.fira-code
        nerd-fonts.iosevka
      ];

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
    })

    { users.users = lib.mapAttrs (_: v: lib.mkIf v.enable { extraGroups = [ "i2c" ]; }) usercfg; }
  ];
}
