{ pkgs, inputs, ... }:

let
  pkgsRust = pkgs.extend inputs.rust-overlay.overlays.default;

  # asterinas commit: 6476ef22ec556d66e337f78d3479b660302bb19c
  # TODO: Auto update theses files to keep my flake pure.
  target = "x86_64-unknown-none";

  # The --userns is slow in zfs: https://github.com/containers/podman/issues/16541
  # And we're using root for that reason... We map only root to current user.
  mk = pkgs.writers.writeBashBin "mk" ''
    set -uex

    sudo podman run \
      --rm \
      -it \
      --privileged \
      --network=host \
      --device=/dev/kvm \
      --uidmap 0:$(id -u):1 \
      --gidmap 0:$(id -g):1 \
      -v $PWD:/root/asterinas \
      func.ink/asterinas/asterinas:0.14.0 \
      make "$@"
  '';
in
# TODO: Make a generic rust shell:
pkgs.mkShell {
  name = "asterinas";

  # To prevent from mixing targets with container rust, only for indexing:
  shellHook = ''
    export CARGO_TARGET_DIR="target.rs.bk"
    mkdir -p .helix
    {
      echo "[language-server.rust-analyzer]"
      echo "config = { cargo = { \"target\" = \"${target}\" } }"
    } > .helix/languages.toml
  '';

  packages = [
    (pkgsRust.rust-bin.nightly."2025-02-01".default.override {
      extensions = [
        "rust-src"
        "rustc-dev"
        "llvm-tools-preview"
        "rust-analyzer"
      ];
      targets = [ target ];
    })
    mk
  ];
}
