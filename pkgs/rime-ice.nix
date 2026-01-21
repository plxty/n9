# @see nixpkgs/pkgs/by-name/ri/rime-data/package.nix
# TODO: home-manager?
# If updated, you might need to run `ibus-daemon -drx` for taking effects.

# From pkgs? args == pkgs?
{
  lib,
  stdenv,
  n9,
  ...
}:

stdenv.mkDerivation rec {
  pname = "rime-ice";
  version = n9.trimRev src;

  # Can't have any 'custom' things, they should be in $XDG, uhho.
  src = n9.sources.rime-ice;
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

  meta = {
    homepage = "https://dvel.me/posts/rime-ice/";
    license = with lib.licenses; [ gpl3 ];
  };
}
