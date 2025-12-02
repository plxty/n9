{
  config,
  lib,
  pkgs,
  pkgsCross,
  ...
}:

let
  cfg = config.toolchain.gcc;
in
{
  options.toolchain.gcc = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
    };
  };

  config.environment.variables = lib.mkIf (cfg.enable && config.shell.cross) {
    CROSS_COMPILE = "${pkgsCross.stdenv.cc.targetPrefix}";
  };

  # TODO: More common libraries here.
  config.variant.shell = lib.mkIf cfg.enable {
    depsBuildBuild = (
      with pkgs;
      [
        gcc
        gdb
        pkg-config
        gnumake
        autoconf
        meson
        ninja
        cmake
        flex
        bison
      ]
    );

    # Cross gcc should be in host, dont' race the packages with build!
    packages = lib.mkIf config.shell.cross (
      with pkgsCross;
      [
        buildPackages.gcc # stdenv.cc
        buildPackages.pkg-config

        # TODO: Avoid "gcc -E -xc" includes the gdb headers.
        buildPackages.gdb
      ]
    );
  };
}
