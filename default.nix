{
  # Impure!
  nixpkgs ? (import <nixpkgs> { }),
  pkgs ? nixpkgs.pkgs,
  ...
}:

let
  inherit (nixpkgs) lib;

  # Mainly for new packages, not for overriding :/
  packagesName = [
    "libkdumpfile"
    "drgn"
    "virtme-ng"
    "rime-ice"
    "proot-rs"
    "mihomo"
    "nix-pack-closure"
  ];

  callPackage = final: prev: package: {
    # In this way you can reference the old packages, to override version.
    # TODO: Downside? Refers to wrong package in some dependencies?
    ${package} = final.callPackage ./pkgs/${package}.nix prev;
  };
in
# Expose only what we have:
lib.getAttrs packagesName (
  pkgs.extend (final: prev: lib.mergeAttrsList (lib.map (callPackage final prev) packagesName))
)
