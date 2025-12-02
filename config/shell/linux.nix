{ lib, ... }:

let
  base = {
    development.linux.enable = true;
  };
  clang = {
    toolchain.clang.enable = true;
  };
in
{
  n9.shell.linux = base;

  n9.shell."linux.clang" = lib.mkMerge [
    base
    clang
  ];

  # TODO: Move to development.
  n9.shell."linux.arm64" = lib.mkMerge [
    base
    {
      shell.triplet = "aarch64-unknown-linux-gnu";
      environment.variables = {
        ARCH = "arm64";
        # https://github.com/containers/libkrunfw/issues/55#issuecomment-2171592122
        NIX_CFLAGS_COMPILE_aarch64_unknown_linux_gnu = "-march=armv8-a+crypto";
      };
    }
  ];

  n9.shell."linux.x86_64" = lib.mkMerge [
    base
    {
      shell.triplet = "x86_64-unknown-linux-gnu";
      environment.variables.ARCH = "x86";
    }
  ];

  # Just fancy.
  n9.shell.rust-for-linux = lib.mkMerge [
    base
    { toolchain.rust.enable = true; }
    clang
  ];
}
