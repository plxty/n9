{
  config,
  lib,
  pkgs,
  n9,
  ...
}:

let
  cfg = n9.lib.forAllUsers config "n9.environment.pop-shell" false;

  enable = lib.any lib.id (cfg (_: v: v.enable or false));
in
{
  options.n9.environment.pop-shell = {
    enable = lib.mkEnableOption "pop-shell";
  };

  config = lib.mkMerge [
    (lib.mkIf enable {
      # TODO: define only once?
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

      # Gnome requires, @see nixpkgs/nixos/modules/services/x11/desktop-managers/gnome.nix
      # It can be safely eliminated, just keep here for a note.
      networking.networkmanager.enable = true;

      environment = {
        sessionVariables.NIXOS_OZONE_WL = "1";

        systemPackages = with pkgs; [
          wl-clipboard
          brave
          ptyxis
          nautilus
          gnome-tweaks
          dconf-editor
        ];

        # Why not in services?
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
    })

    {
      home-manager.users = lib.mergeAttrsList (
        cfg (
          userName: v:
          lib.optionalAttrs (v.enable or false) {
            ${userName} = {
              home.packages = with pkgs; [ pop-launcher ];

              # TODO: dconf
              programs.gnome-shell = {
                enable = true;
                extensions = [
                  { package = pkgs.gnomeExtensions.pop-shell; }
                  { package = pkgs.gnomeExtensions.customize-ibus; }
                ];
              };
            };
          }
        )
      );
    }
  ];
}
