{
  config,
  lib,
  pkgs,
  self,
  ...
}:

let
  cfg = config.n9.environment.pop-shell;
  dconf = import ../dconf-gnome.nix { inherit lib; };
in
{
  options.n9.environment.pop-shell = {
    enable = lib.mkEnableOption "pop-shell";
  };

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      dconf-editor
      dconf2nix
    ];

    programs.gnome-shell = {
      enable = true;
      extensions = [
        { package = pkgs.gnomeExtensions.brightness-control-using-ddcutil; }
        { package = pkgs.gnomeExtensions.switcher; }
        { package = self.inputs.paperwm.packages.${pkgs.system}.default; }
        { package = pkgs.gnomeExtensions.customize-ibus; }
      ];
    };

    inherit (dconf) dconf;
  };
}
