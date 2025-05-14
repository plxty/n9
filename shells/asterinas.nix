{ pkgs, ... }:

let
  # The --userns is slow in zfs: https://github.com/containers/podman/issues/16541
  # And we're using root for that reason... We map only root to current user.
  makeWrapper = pkgs.writers.writeBashBin "make" ''
    set -xeu
    cd $(git rev-parse --show-toplevel)
    exec sudo podman run --rm -it --privileged --network=host --device=/dev/kvm \
      --uidmap 0:$(id -u):1 --gidmap 0:$(id -g):1 -v $PWD:/root/asterinas \
      docker.1ms.run/asterinas/asterinas:$(cat DOCKER_IMAGE_VERSION) make "$@"
  '';
in
{
  n9.shell.asterinas = {
    triplet = "x86_64-unknown-none";
    gcc.enable = false;

    # asterinas commit: 6476ef22ec556d66e337f78d3479b660302bb19c
    # TODO: Auto update theses files to keep my flake pure.
    rust = {
      enable = true;
      channel = "nightly";
      version = "2025-02-01";
      extensions = [
        "rust-src"
        "rustc-dev"
        "llvm-tools-preview"
        "rust-analyzer"
      ];
    };

    packages = [
      makeWrapper
    ];

    # To prevent from mixing targets with container rust, only for indexing:
    shellHooks = [
      ''
        export CARGO_TARGET_DIR="target.rs.bk"
        mkdir -p .helix
        {
          echo "[language-server.rust-analyzer]"
          echo "config = { cargo = { \"target\" = \"x86_64-unknown-none\" } }"
        } > .helix/languages.toml
      ''
    ];
  };
}
