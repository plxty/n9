{ pkgs, inputs, ... }:

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
  pkgsRust = pkgs.extend inputs.rust-overlay.overlays.default;
  arch = { aarch64-linux = "arm64"; }.${target};

  mk = pkgs.writers.writeBashBin "mk" ''
    make ARCH=${arch} CROSS_COMPILE=${pkgsCross.stdenv.cc.targetPrefix} V=1 "$@"
  '';

  mkllvm = pkgs.writers.writeBashBin "mkllvm" ''
    make ARCH=${arch} LLVM=1 V=1 "$@"
  '';
in
pkgsCross.mkShell {
  name = "kernel";

  depsBuildBuild = with pkgs; [
    # rust-for-linux
    (pkgsRust.rust-bin.stable.latest.default.override {
      extensions = [ "rust-src" ];
    })
    rust-bindgen
    clang # TODO: clang isn't used for cross compile?
    lld
    # normal stuff
    gcc
    flex
    bison
    ncurses # menuconfig
  ];

  packages = [
    mk
    mkllvm
  ];
}
