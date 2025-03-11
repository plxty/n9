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

    ../configure \
      --target-list=${targetList} \
      ${cross.configure} \
      --static \
      --enable-kvm \
      --enable-linux-io-uring \
      --enable-vhost-net \
      --disable-tools \
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

  # We need to build a static QEMU to run on boards:
  inputsFrom = with cross.pkgs.pkgsStatic; [
    # Keep it simple to reduce dependency build time:
    (qemu.override { minimal = true; })
    # Requires some buildInputs by glib:
    glib
  ];

  nativeBuildInputs = [
    # We need a native gcc as well to build some QEMU objects:
    pkgs.gcc
  ];

  # Don't know why placing it to nativeBuildInputs won't work, because it's a library?
  # https://discourse.nixos.org/t/use-buildinputs-or-nativebuildinputs-for-nix-shell/8464
  # > nativeBuildInputs: Should be used for commands which need to run at build time (e.g. cmake) or shell hooks (e.g. autoPatchelfHook). These packages will be of the buildPlatforms architecture, and added to PATH.
  # > buildInputs: Should be used for things that need to be linked against (e.g. openssl). These will be of the hostPlaform’s architecture. With strictDeps = true; (or by extension cross-platform builds), these will not be added to PATH. However, linking related variables will capture these packages (e.g. NIX_LD_FLAGS, CMAKE_PREFIX_PATH, PKG_CONFIG_PATH)
  buildInputs = [
    # For static libc it should be specified individually:
    cross.pkgs.glibc.static
  ];

  packages = [
    configure
    build
  ];
}
