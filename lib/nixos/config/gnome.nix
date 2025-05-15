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
  config = n9.mkIfUsers (v: v.enable) usercfg {
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
        (n9.patch pop-wallpapers "pop-wallpapers-stable-dir")
        wl-clipboard
        (brave.override (prev: {
          commandLineArgs = builtins.concatStringsSep " " [
            (prev.commandLineArgs or "")
            "--wayland-text-input-version=3"
            "--sync-url=https://brave-sync.pteno.cn/v2"
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
