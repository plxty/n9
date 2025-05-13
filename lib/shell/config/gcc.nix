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

  # TODO: More common libraries here.
  config = lib.mkIf cfg.enable {
    depsBuildBuild =
      (with pkgs; [
        gcc
        gdb
        gnumake
        autoconf
        meson
        ninja
        cmake
        flex
        bison
      ])
      ++ lib.optionals (pkgs.system != config.target) (
        with pkgsCross;
        [
          buildPackages.gcc # stdenv.cc
          buildPackages.gdb
        ]
      );

    # TODO: is it neccessary?
    shellHook = lib.optionalString (pkgs.system != config.target) ''
      export CROSS_COMPILE="${pkgsCross.stdenv.cc.targetPrefix}"
    '';
  };
}
