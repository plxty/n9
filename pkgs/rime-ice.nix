# @see nixpkgs/pkgs/by-name/ri/rime-data/package.nix
# TODO: home-manager?
# If updated, you might need to run `ibus-daemon -drx` for taking effects.

# From pkgs? args == pkgs?
{
  lib,
  stdenv,
  fetchFromGitHub,
  unstableGitUpdater,
  ...
}:

stdenv.mkDerivation {
  pname = "rime-ice";
  src = fetchFromGitHub {
    owner = "iDvel";
    repo = "rime-ice";
    rev = "17c1f2559c0592b1fce84bbf73b148652037912e";
    hash = "sha256-UnE2Mj0dDCkjLsrVoh3q3/eSuGHBGwhJYjmW9m9tvwA=";
  };
  version = "0-unstable-2026-01-31";

  # Can't have any 'custom' things, they should be in $XDG, uhho.
  patches = [ ../pkgs/patches/rime-ice-taste.patch ];

  # https://discourse.nixos.org/t/what-does-runhook-do/13861/3
  # Reference other package with `${}` which will expands in nix,
  # reference for out dir with `$out` which will expands in build shell script.

  # TODO: Build as https://aur.archlinux.org/cgit/aur.git/tree/PKGBUILD?h=rime-ice-git
  # ${librime}/bin/rime_deployer --build
  buildPhase = ''
    runHook preBuild
    rm -rf .* go.work others LICENSE README.md \
      double_pinyin.schema.yaml \
      double_pinyin_flypy.schema.yaml \
      double_pinyin_jiajia.schema.yaml \
      double_pinyin_mspy.schema.yaml \
      double_pinyin_sogou.schema.yaml \
      double_pinyin_ziguang.schema.yaml \
      radical_pinyin.dict.yaml \
      radical_pinyin.schema.yaml \
      t9.schema.yaml \
      symbols_caps_v.yaml \
      symbols_v.yaml
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p "$out/share/rime-data"
    cp -r . "$out/share/rime-data"
    runHook postInstall
  '';

  passthru.updateScript = unstableGitUpdater { hardcodeZeroVersion = true; };

  meta = {
    homepage = "https://dvel.me/posts/rime-ice/";
    license = with lib.licenses; [ gpl3 ];
  };
}
