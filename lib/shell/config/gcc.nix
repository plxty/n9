{
  config,
  lib,
  pkgs,
  pkgsCross,
  ...
}:

let
  cfg = config.gcc;
in
{
  options.gcc = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
    };
  };

  # TODO: Some common libraries here.
  config.passthru = lib.mkIf cfg.enable {
    depsBuildBuild =
      [
        pkgs.gcc
        pkgs.gdb
      ]
      ++ lib.optionals (pkgs.system != config.target) [
        pkgsCross.buildPackages.gcc # pkgsCross.stdenv.cc
        pkgsCross.buildPackages.gdb
      ];
  };
}
