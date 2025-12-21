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

  patches =
    pkg: attrs:
    pkg.overrideAttrs (prev: {
      patches =
        (prev.patches or [ ])
        ++ (lib.map (v: if (lib.typeOf v) == "string" then ./patches/${v}.patch else v) attrs);
    });
  patch = pkg: attr: patches pkg [ attr ];

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
  mihomo = patch (
    let
      src = n9.sources.mihomo;
    in
    n9.assureVersion prev.mihomo src.version {
      inherit src;
      vendorHash = "sha256-WwbuNplMkH5wotpHasQbwK85Ymh6Ke4WL1LTLDWvRFk=";
    }
  ) "mihomo-taste";

  # Fix for wrongly wechat version... FIXME: kind of unstable, use niv?
  # The appimage is hard to override, therefore hacking the fetchurl...
  wechat = prev.wechat.override (prev: {
    fetchurl =
      { url, ... }@attrs:
      prev.fetchurl (
        attrs
        // (lib.optionalAttrs (lib.hasSuffix "/WeChatLinux_x86_64.AppImage" url) {
          url = "https://dldir1v6.qq.com/weixin/Universal/Linux/WeChatLinux_x86_64.AppImage";
          hash = "sha256-+r5Ebu40GVGG2m2lmCFQ/JkiDsN/u7XEtnLrB98602w=";
        })
      );
  });

  ppp = patch prev.ppp "ppp-run-resolv";

  # What burns:
  colmena = patch inputs.colmena.packages.${prev.stdenv.system}.colmena "colmena-taste";

  # The home-manager doesn't have an option to customize openssh, thus we make
  # it global. TODO: submit patches to community?
  # openssh = prev.opensshWithKerberos; will cause inifinite recursion, why?
  openssh = prev.openssh.override {
    withKerberos = lib.trace "overlay derivition created" true;
  };

  # Helix, and skip check for our own builds, to speed up:
  helix = (patch prev.helix "helix-taste").overrideAttrs {
    doCheck = false;
  };

  ibus-engines = prev.ibus-engines // {
    rime = (patch prev.ibus-engines.rime "ibus-rime-temp-ascii").override {
      rimeDataPkgs = [ final.rime-ice ];
    };
  };

  librime = patch prev.librime "librime-temp-ascii";

  # To skip some test fails... 25.11 is too new, which fails always...
  # FIXME: Remove me when done!
  python313 =
    let
      packageOverrides =
        pyton-final: python-prev:
        let
          skipCheck =
            pkg:
            python-prev.${pkg}.overrideAttrs {
              doInstallCheck = false;
              doCheck = false;
            };
          skipCheckIf = cond: pkgs: lib.genAttrs pkgs (if cond then skipCheck else n: python-prev.${n});
        in
        (skipCheckIf (prev.stdenv.system == "aarch64-linux") [ "aiohttp" ])
        // (skipCheckIf (prev.stdenv.system == "aarch64-darwin") [ "twisted" ]);
    in
    prev.python313.override { inherit packageOverrides; };

  # Speed up perf + compressed debug info:
  perf = patch prev.perf "perf-taste";
}
