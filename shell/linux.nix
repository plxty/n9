{ pkgs, inputs, ... }:

# The cross.pkgs.stdenv will handle (build,host,target) well, and we just use it:
# https://github.com/NixOS/nixpkgs/blob/master/pkgs/stdenv/cross/default.nix
# @see NixOS Reference: Dependency propagation
# build: current the platform, host: the cross compile toolchains, target: eventually runs at
# https://github.com/NixOS/nixpkgs/issues/35543

# linux.<arch>.<toolchain>
#       ^^^^^^              arm64,x86
#              ^^^^^^^^^^^  gcc,clang
# Note: x86 only supports 64 bit.
let
  inherit (pkgs) system;
  inherit (inputs.nixpkgs) lib;

  # TODO: Host rust and build rust? Seems no difference...
  pkgsRust = pkgs.extend inputs.rust-overlay.overlays.default;

  mkLinux =
    arch: toolchain:
    let
      target =
        {
          arm64 = "aarch64-linux";
          x86 = "x86_64-linux";
        }
        .${arch};

      # TODO: Merge with QEMU
      pkgsCross =
        if target == system then pkgs else { arm64 = pkgs.pkgsCross.aarch64-multiplatform-musl; }.${arch};

      mkShell =
        if toolchain == "gcc" then
          pkgsCross.mkShell
        else
          pkgsCross.mkShell.override { stdenv = pkgsCross.clangStdenv; };

      # M="vmlinux" C="-o ..." 1
      oneStep = pkgs.writers.writeBashBin "1" ''
        set -uex

        make ARCH=${arch} -j$(nproc --ignore 3) \
          ${
            if toolchain == "gcc" then
              if target != system then "CROSS_COMPILE=${pkgsCross.stdenv.cc.targetPrefix}" else ""
            else
              "LLVM=1" # FIXME: LLVM still broken...
          } \
          ''${M:-}
        ./scripts/clang-tools/gen_compile_commands.py ''${C:-}
      '';
    in
    mkShell {
      name = "linux";

      # Tools in host:
      depsBuildBuild =
        with pkgs;
        [
          # rust-for-linux
          (pkgsRust.rust-bin.stable.latest.default.override {
            extensions = [ "rust-src" ];
          })
          rust-bindgen
          # rest of all
          flex
          bison
          ncurses
          bc
          pkg-config
          libelf
        ]
        ++ lib.optionals (toolchain == "clang") [
          libllvm
          lld # using host lld seems fine...
        ];

      packages = [ oneStep ];
    };
in
lib.genAttrs [ "arm64" "x86" ] (
  arch: lib.genAttrs [ "gcc" "clang" ] (toolchain: mkLinux arch toolchain)
)
