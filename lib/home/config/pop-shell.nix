{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.n9.environment.pop-shell;
in
{
  options.n9.environment.pop-shell = {
    enable = lib.mkEnableOption "pop-shell";
  };

  config = lib.mkIf cfg.enable {
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
