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
    "mihomo-unstable"
    "nix-pack-closure"
  ];

  callPackage = final: prev: package: {
    # Just don't infinite recursion...
    ${package} = prev.callPackage ./pkgs/${package}.nix { };
  };
in
# Expose only what we have:
lib.getAttrs packagesName (
  pkgs.extend (final: prev: lib.mergeAttrsList (lib.map (callPackage final prev) packagesName))
)
