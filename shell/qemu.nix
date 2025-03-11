{ system, nixpkgs, ... }:

let
  pkgs = nixpkgs.legacyPackages.${system};
in
pkgs.mkShell {
  # https://github.com/NixOS/nixpkgs/blob/master/pkgs/applications/virtualization/qemu/default.nix
  name = "qemu";

  inputsFrom = with pkgs; [
    qemu_full
  ];
}
