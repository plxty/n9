{ pkgs, ... }:

pkgs.mkShell {
  name = "rust";

  packages = with pkgs; [
    rustc
    cargo
    rust-analyzer
    # can switch to other rust version if you want:
    rustup
  ];
}
