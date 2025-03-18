{ pkgs, inputs, ... }:

let
  pkgsRust = pkgs.extend inputs.rust-overlay.overlays.default;

  # asterinas commit: 6476ef22ec556d66e337f78d3479b660302bb19c
  # TODO: Auto update theses files to keep my flake pure.
  target = "x86_64-unknown-none";
  rust = (
    pkgsRust.rust-bin.nightly."2025-02-01".default.override {
      extensions = [
        "rust-src"
        "rustc-dev"
        "llvm-tools-preview"
        "rust-analyzer"
      ];
      targets = [ target ];
    }
  );

  # Make wrapper to rust-analyzer to respect the targets:
  rust-analyzer = pkgs.writers.writeBashBin "rust-analyzer" ''
    if [[ ! -f .cargo/config.toml ]]; then
      mkdir -p .cargo
      {
        echo "[build]"
        echo "target = \"${target}\""
      } > .cargo/config.toml
    fi
    ${rust}/bin/rust-analyzer "$@"
  '';
in
# TODO: Make a generic rust shell:
pkgs.mkShell {
  name = "asterinas";

  packages = [
    rust-analyzer # wrapper should goes first
    rust
  ];
}
