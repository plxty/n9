{ pkgs, ... }:

# The cross.pkgs.stdenv will handle (build,host,target) well, and we just use it:
# https://github.com/NixOS/nixpkgs/blob/master/pkgs/stdenv/cross/default.nix
# @see NixOS Reference: Dependency propagation
# build: current the platform, host: the cross compile toolchains, target: eventually runs at
# https://github.com/NixOS/nixpkgs/issues/35543

let
  inherit (pkgs) system;
  target = "aarch64-linux";

  pkgsCross =
    if target == system then
      pkgs
    else
      # eq. 'pkgs = import <nixpkgs> { crossSystem.config = "..."; };'
      { aarch64-linux = pkgs.pkgsCross.aarch64-multiplatform-musl; }.${target};
  prefix = pkgsCross.stdenv.cc.targetPrefix;
  targetList = { aarch64-linux = "aarch64-softmmu"; }.${target};

  # TODO: other targets like rv64?
  configure = pkgs.writers.writeBashBin "configure" ''
    set -xeu

    if [[ ! -f qemu-options.hx ]]; then
      echo 'Run me inside a existing QEMU source!'
      exit 1
    fi

    # .clang-format from libslirp, maybe the same?
    if [[ ! -f .clang-format ]]; then
      curl -L -o .clang-format \
        'https://gitlab.com/qemu-project/libslirp/-/raw/master/.clang-format?ref_type=heads&inline=false'
    fi

    mkdir -p build
    cd build

    CONFIGURE_FLAGS=(
      --target-list=${targetList}
      --static
      --disable-strip
      # To workaround ASM_FINAL_SPEC in GCC that trying to run native objcopy:
      --disable-split-debug
      --disable-tools
      --disable-guest-agent
      # GIO has problem with static link musl-c, causing redefinition of crc32c:
      --disable-gio
      --enable-kvm
      --enable-linux-io-uring
      --enable-vhost-net
    )
    if [[ "${prefix}" != "" ]]; then
      CONFIGURE_FLAGS+=(--cross-prefix=${prefix})
    fi

    ../configure "''${CONFIGURE_FLAGS[@]}" "$@"
    ninja -t compdb > compile_commands.json
    # The https://github.com/llvm/llvm-project/pull/129459 just merged days ago,
    # we still need a very naive way (using clangd config) to play with it.
    # Note: the --query-driver only plays well within LC_ALL=C environment.
    # Run `clangd --log=verbose --check=system/main.c` to verify.
    {
      echo "CompileFlags:"
      echo "  Add:"
      for INC in $(${prefix}gcc -E -Wp,-v -xc /dev/null -fsyntax-only 2>&1 | sed -n 's,^ ,,p'); do
        echo "    - -I$INC"
      done
    } > ../.clangd
  '';

  mk = pkgs.writers.writeBashBin "mk" ''
    make -C build -j $(nproc --ignore=2) "$@"
  '';
in
pkgsCross.mkShell {
  name = "qemu";

  # Like configure or some code-gen tools that runs on build:
  depsBuildBuild = with pkgs; [
    meson
    ninja
    gcc # needs for hexagon
  ];

  # Mostly the cross compilers, kind of similar to depsBuildBuild:
  nativeBuildInputs = with pkgsCross.buildPackages; [
    gcc
    pkg-config
  ];

  # Making dependent libraries static, pkgsStatic.qemu is broken, and won't work
  # event { minimal = true; }, causing the inputsFrom a little bit awkward.
  buildInputs = with pkgsCross.pkgsStatic; [
    glib
    liburing
  ];

  packages = [
    configure
    mk
  ];
}
