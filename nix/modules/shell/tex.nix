{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.tex;
in
{
  options.tex = {
    enable = lib.mkEnableOption "tex";

    packages = lib.mkOption {
      # TODO: listOf package?
      type = lib.types.listOf lib.types.str;
      default = [
        "xifthen"
        "ifmtarg"
        "titlesec"
        "enumitem"
        "xecjk"
      ];
    };
  };

  config = lib.mkIf cfg.enable {
    packages = [
      (pkgs.texliveMedium.withPackages (pkgs: lib.map (v: pkgs.${v}) cfg.packages))
    ];
  };
}
