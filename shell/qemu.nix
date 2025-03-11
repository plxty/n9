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
          pkgs = pkgs.pkgsCross.aarch64-multiplatform;
          configure = "--cross-prefix=aarch64-unknown-linux-gnu-";
        };
      }
      .${target};
  targetList = { aarch64-linux = "aarch64-softmmu"; }.${target};

  fetch = pkgs.writers.writeBashBin "fetch" ''
    set -xeu

    if [[ ! -d qemu ]]; then
      curl https://mirrors.tuna.tsinghua.edu.cn/git/qemu/qemu.sh | bash
    fi

    cd qemu
    echo "use flake n9#qemu" >> .envrc
    direnv allow
  '';

  # TODO: other targets like rv64?
  configure = pkgs.writers.writeBashBin "configure" ''
    set -xeu

    if [[ ! -f qemu-options.hx ]]; then
      echo 'Run `fetch` first or cd to existing QEMU source!'
      exit 1
    fi

    mkdir -p build
    cd build

    ../configure \
      --target-list=${targetList} \
      ${cross.configure} \
      --static \
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

  inputsFrom = with cross.pkgs; [
    # Keep it simple to reduce dependency build time:
    (qemu.override { minimal = true; })
    # Requires some buildInputs by glib:
    glib
  ];

  nativeBuildInputs = [
    # We need a native gcc as well to build some QEMU objects:
    pkgs.gcc
  ];

  packages = [
    fetch
    configure
    build
  ];
}
