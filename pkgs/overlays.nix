# https://wiki.nixos.org/wiki/Overlays
# TODO: But we should ensure there's no extra dependencies.
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
  rime-ice = mkPackage ./rime-ice.nix;
  virtme-ng = mkPackage ./virtme-ng.nix;
  libkdumpfile = mkPackage ./libkdumpfile.nix;
  drgn = mkPackage ./drgn.nix;
  gitcache = mkPackage ./gitcache.nix;

  # Upgrading some packages ourselves...
  iterm2 = prev.iterm2.overrideAttrs rec {
    version = lib.replaceStrings [ "_" ] [ "." ] src.version;
    src = n9.sources.iterm2;
    nativeBuildInputs = [ prev.unzip ];
    unpackPhase = ''unzip $src'';
    sourceRoot = "iTerm.app"; # avoid /Applications/iTerm2.app/iTerm.app appears
  };

  # And mihomo...
  mihomo = prev.mihomo.overrideAttrs rec {
    version = src.version;
    src = n9.sources.mihomo;
    patches = [ ]; # FIXME: ...
    vendorHash = "sha256-t+v+szM5uXRy173tAtRf+IqiGNHaL6nNRgf6OZmeJyQ=";
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
