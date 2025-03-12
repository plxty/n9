{ system, nixpkgs, ... }:

# The cross.pkgs.stdenv will handle (build,host,target) well, and we just use it:
# https://github.com/NixOS/nixpkgs/blob/master/pkgs/stdenv/cross/default.nix
# @see NixOS Reference: Dependency propagation
# build: current the platform, host: the cross compile toolchains, target: eventually runs at
# https://github.com/NixOS/nixpkgs/issues/35543

let
  target = "aarch64-linux";

  pkgs = nixpkgs.legacyPackages.${system};
  cross =
    if target == system then
      {
        inherit pkgs;
        configure = "";
      }
    else
      {
        aarch64-linux = {
          # eq. 'pkgs = import <nixpkgs> { crossSystem.config = "..."; };'
          pkgs = pkgs.pkgsCross.aarch64-multiplatform-musl;
          configure = "--cross-prefix=aarch64-unknown-linux-musl-";
        };
      }
      .${target};
  targetList = { aarch64-linux = "aarch64-softmmu"; }.${target};

  # TODO: other targets like rv64?
  configure = pkgs.writers.writeBashBin "configure" ''
    set -xeu

    if [[ ! -f qemu-options.hx ]]; then
      echo 'Run me inside a existing QEMU source!'
      exit 1
    fi

    if [[ ! -f .envrc ]]; then
      echo "use flake n9#qemu" > .envrc
      direnv allow
    fi

    mkdir -p build
    cd build

    # MUST disable split-debug to workaround ASM_FINAL_SPEC in GCC that trying to run native objcopy:
    # (The split-debug may still in development, it occurs in the latest QEMU commit.)
    # GIO has problem with static link, causing redefinition of crc32c.
    ../configure \
      --target-list=${targetList} \
      ${cross.configure} \
      --static \
      --disable-strip \
      --disable-split-debug \
      --disable-tools \
      --disable-guest-agent \
      --disable-gio \
      --enable-kvm \
      --enable-linux-io-uring \
      --enable-vhost-net \
      "$@"

    ninja -t compdb > compile_commands.json
  '';

  build = pkgs.writers.writeBashBin "build" ''
    make -C build -j $(nproc --ignore=2) "$@"
  '';
in
cross.pkgs.mkShell {
  name = "qemu";

  # Like configure or some code-gen tools that runs on build:
  depsBuildBuild = with pkgs; [
    meson
    ninja
    python3
    gcc # needs for hexagon
  ];

  # Mostly the cross compilers, kind of similar to depsBuildBuild:
  nativeBuildInputs = with cross.pkgs.buildPackages; [
    gcc
    pkg-config
  ];

  # Making dependent libraries static, pkgsStatic.qemu is broken, and won't work
  # event { minimal = true; }, causing the inputsFrom a little bit awkward.
  buildInputs = with cross.pkgs.pkgsStatic; [
    glib
    liburing
  ];

  packages = [
    configure
    build
  ];
}
