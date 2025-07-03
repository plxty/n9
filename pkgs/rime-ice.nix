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

let
  src = n9.sources.rime-ice;
in
stdenv.mkDerivation {
  pname = "rime-ice";
  version = src.rev;

  # Can't have any 'custom' things, they should be in $XDG, uhho.
  inherit src;
  patches = [ ../pkgs/patches/rime-ice-taste.patch ];

  # https://discourse.nixos.org/t/what-does-runhook-do/13861/3
  # Reference other package with `${}` which will expands in nix,
  # reference for out dir with `$out` which will expands in build shell script.

  # TODO: Build as https://aur.archlinux.org/cgit/aur.git/tree/PKGBUILD?h=rime-ice-git
  # ${librime}/bin/rime_deployer --build
  buildPhase = ''
    runHook preBuild
    rm -rf .* opencc others LICENSE README.md
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
