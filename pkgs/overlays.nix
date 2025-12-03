# https://wiki.nixos.org/wiki/Overlays
# TODO: But we should ensure there's no extra dependencies.
# Patches aren't included, to keep the overlay clean. Or?
{ inputs, ... }:

final: prev:
let
  inherit (prev) lib;
  n9 = import ../lib {
    inherit lib inputs;
  };

  mkPackage = pkg: final.callPackage pkg { inherit n9 inputs; };
in
{
  # Maybe some new toys:
  rime-ice = mkPackage ./rime-ice.nix;
  virtme-ng = mkPackage ./virtme-ng.nix;
  libkdumpfile = mkPackage ./libkdumpfile.nix;
  drgn = mkPackage ./drgn.nix;
  gitcache = mkPackage ./gitcache.nix;

  # Upgrading some packages ourselves...
  iterm2 =
    let
      src = n9.sources.iterm2;
      version = lib.replaceStrings [ "_" ] [ "." ] src.version;
    in
    n9.assureVersion prev.iterm2 version {
      inherit src;
      nativeBuildInputs = [ prev.unzip ];
      unpackPhase = ''unzip $src'';
      sourceRoot = "iTerm.app"; # avoid /Applications/iTerm2.app/iTerm.app appears
    };

  flashspace =
    let
      src = n9.sources.flashspace;
    in
    n9.assureVersion prev.flashspace src.version {
      inherit src;
      nativeBuildInputs = [ prev.unzip ];
      unpackPhase = ''unzip $src'';
      sourceRoot = "flashspace.app";
    };

  # And mihomo...
  mihomo =
    let
      src = n9.sources.mihomo;
    in
    n9.assureVersion prev.mihomo src.version {
      inherit src;
      vendorHash = "sha256-WwbuNplMkH5wotpHasQbwK85Ymh6Ke4WL1LTLDWvRFk=";
    };

  # The home-manager doesn't have an option to customize openssh, thus we make
  # it global. TODO: submit patches to community?
  # openssh = prev.opensshWithKerberos; will cause inifinite recursion, why?
  openssh = prev.openssh.override {
    withKerberos = lib.trace "overlay derivition created" true;
  };

  ibus-engines = prev.ibus-engines // {
    rime = (n9.patch prev.ibus-engines.rime "ibus-rime-temp-ascii").override {
      rimeDataPkgs = [ final.rime-ice ];
    };
  };

  librime = n9.patch prev.librime "librime-temp-ascii";
}
