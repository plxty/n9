{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.toolchain.tex;
in
{
  options.toolchain.tex = {
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

  config.environment.packages = lib.mkIf cfg.enable [
    (pkgs.texliveMedium.withPackages (pkgs: lib.map (v: pkgs.${v}) cfg.packages))
  ];
}
