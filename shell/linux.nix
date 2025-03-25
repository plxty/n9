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
# TODO: Generic way to do the cross compiling...
let
  inherit (pkgs) system;
  inherit (inputs.nixpkgs) lib;
  pkgsRust = pkgs.extend inputs.rust-overlay.overlays.default;
  underscore = lib.replaceStrings [ "-" ] [ "_" ];

  mkLinux =
    arch: toolchain:
    let
      target =
        {
          arm64 = "aarch64-linux";
          x86 = "x86_64-linux";
        }
        .${arch};
      # Linux requires no <vendor> part, to disable the warning of clang...
      # This triggers building of gcc, will take some time for the clang...
      pkgsCross =
        if target == system then
          pkgs
        else
          import inputs.nixpkgs {
            inherit system;
            crossSystem.config = "${target}-gnu";
          };
      triplet = {
        build = pkgs.stdenv.buildPlatform.config;
        target = pkgsCross.stdenv.targetPlatform.config;
      };

      # LLVM cross compile is quite annoying, especially in Linux:
      # 1. The linux uses clang for both depsBuildBuild and depsBuildHost
      # 2. NixOS wrapped clang in stdenv for both cross and non-cross
      # 3. They can't coexists due to linux hardcoded the host clang and target
      # Therefore we can only write a little wrapper to help us call the right
      # side of clang, kind of ugly :(
      # Other tools (e.g. lld) from host seems usable, only clang needs it.
      # P.S. The stdenv.cc.cc is the unwrapped drv of compiler, use at risk.
      # TODO: arm-linux-gnueabi
      clangWrapper = pkgs.writers.writeBashBin "clang" ''
        for __clang_arg in "$@"; do
          if [[ "$__clang_arg" == "--target=${triplet.target}" ]]; then
            exec ${pkgsCross.clangStdenv.cc}/bin/${triplet.target}-clang "$@"
          fi
        done
        exec ${pkgs.clangStdenv.cc}/bin/clang "$@"
      '';

      makeWrapper = pkgs.writers.writeBashBin "make" ''
        if [[ "$1" == "compdb" ]]; then
          shift 1
          exec ./scripts/clang-tools/gen_compile_commands.py "$@"
        fi
        exec ${pkgs.gnumake}/bin/make "$@"
      '';
    in
    # CC is set by ourselves (with CROSS_COMPILE or LLVM).
    pkgsCross.mkShellNoCC {
      name = "linux";

      # Setup the customized stdenv (the nix sets CC, LD, ... by default):
      shellHook =
        ''
          export ARCH="${arch}"
          export MAKEFLAGS="-j$(nproc --ignore 3)"
        ''
        + lib.optionalString (toolchain == "gcc" && target != system) ''
          export CROSS_COMPILE="${pkgsCross.stdenv.cc.targetPrefix}"
        ''
        + lib.optionalString (toolchain == "clang") ''
          export NIX_CFLAGS_COMPILE+=" -Qunused-arguments"
          export NIX_CFLAGS_COMPILE_${underscore triplet.build}+=" -Qunused-arguments"
          export NIX_CFLAGS_COMPILE_${underscore triplet.target}+=" -Qunused-arguments"
          export LLVM="1"
        '';

      # Tools in host (like packages):
      depsBuildBuild =
        with pkgs;
        [
          # own
          makeWrapper
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
          openssl
          # debug, still flavor of gdb instead of lldb:
          pkgsCross.buildPackages.gdb
        ]
        ++ lib.optionals (toolchain == "gcc") [
          gcc
          pkgsCross.stdenv.cc
        ]
        ++ lib.optionals (toolchain == "clang") [
          clangWrapper
          lld
          libllvm
        ];
    };
in
lib.genAttrs [ "arm64" "x86" ] (
  arch: lib.genAttrs [ "gcc" "clang" ] (toolchain: mkLinux arch toolchain)
)
