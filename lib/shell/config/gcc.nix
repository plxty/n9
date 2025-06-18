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
    depsBuildBuild = (
      with pkgs;
      [
        gcc
        gdb
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
    packages = lib.mkIf config.cross (
      with pkgsCross;
      [
        buildPackages.gcc # stdenv.cc
        buildPackages.gdb
      ]
    );
  };
}
