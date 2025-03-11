{ system, nixpkgs, ... }:

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
          # eq to 'pkgs = import <nixpkgs> { crossSystem.config = "..."; };'
          # It seems the static QEMU is using musl-c, we're trying to keep it up:
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
    ../configure \
      --target-list=${targetList} \
      ${cross.configure} \
      --static \
      --disable-strip \
      --disable-split-debug \
      --disable-tools \
      --disable-guest-agent \
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
# https://github.com/NixOS/nixpkgs/blob/master/pkgs/applications/virtualization/qemu/default.nix
# https://nixos.wiki/wiki/Cross_Compiling
# The cross.pkgs.stdenv will handle (build,host,target) well, and we just use it:
# https://github.com/NixOS/nixpkgs/blob/master/pkgs/stdenv/cross/default.nix
cross.pkgs.mkShell {
  name = "qemu";

  # Making dependent libraries static:
  inputsFrom = with cross.pkgs.pkgsStatic; [
    # Keep it simple to reduce dependency build time in nix:
    (qemu.override { minimal = true; })
    # The glib requires some of the depencies be installed:
    glib
  ];

  # In cross compile (in my own opinion),
  # build: current the platform
  # host: the cross compile toolchains
  # target: eventually runs at
  depsBuildBuild = [
    # QEMU needs for hexagon:
    pkgs.gcc
  ];

  # https://discourse.nixos.org/t/use-buildinputs-or-nativebuildinputs-for-nix-shell/8464
  # @see NixOS Reference: Dependency propagation
  # buildInputs = with cross.pkgs; [
  #   # Need both dynamic (for meson configure) and static (for building to target) glibc:
  #   glibc
  #   glibc.static
  # ];

  packages = [
    configure
    build
  ];
}
