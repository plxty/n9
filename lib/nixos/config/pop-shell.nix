{
  config,
  lib,
  pkgs,
  self,
  ...
}:

let
  # @see lib/home/config/pop-shell.nix
  # TODO: Rename to gnome?
  usercfg = self.lib.users "pop-shell" (v: v.n9.environment.pop-shell) config;
in
{
  config = lib.mkMerge [
    (self.lib.mkIfUsers (v: v.enable) usercfg {
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
        sessionVariables.NIXOS_OZONE_WL = "1";

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
