{ pkgs, ... }:

# The cross.pkgs.stdenv will handle (build,host,target) well, and we just use it:
# https://github.com/NixOS/nixpkgs/blob/master/pkgs/stdenv/cross/default.nix
# @see NixOS Reference: Dependency propagation
# build: current the platform, host: the cross compile toolchains, target: eventually runs at
# https://github.com/NixOS/nixpkgs/issues/35543

let
  inherit (pkgs) system;
  target = "aarch64-linux";

  # TODO: Merge with QEMU
  pkgsCross =
    if target == system then
      pkgs
    else
      { aarch64-linux = pkgs.pkgsCross.aarch64-multiplatform-musl; }.${target};
  arch = { aarch64-linux = "ARM64"; }.${target};
  prefix = pkgsCross.stdenv.cc.targetPrefix;

  kmake = pkgs.writers.writeBashBin "kmake" ''
    make ARCH=${arch} CROSS_COMPILE=${prefix} V=1 "$@"
  '';
in
pkgsCross.mkShell {
  name = "kernel";

  depsBuildBuild = with pkgs; [
    gcc
  ];

  nativeBuildInputs = with pkgsCross.buildPackages; [
    gcc
    pkg-config
  ];

  packages = [
    kmake
  ];
}
