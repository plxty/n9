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
    shellHooks = [
      ''export MAKEFLAGS="-j$(nproc --ignore 3)"''
    ];

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
    packages = lib.mkIf config.cross (
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
