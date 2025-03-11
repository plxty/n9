# @see nixpkgs/pkgs/by-name/ri/rime-data/package.nix
# TODO: home-manager?
# If updated, you might need to run `ibus-daemon -drx` for taking effects.

# From pkgs? args == pkgs?
{
  lib,
  stdenv,
  fetchFromGitHub,
  librime,
  ...
}:

let
  pname = "rime-ice";
  version = "22699f5ade55cf27b33417e7e53346218e8c83e4";
in
stdenv.mkDerivation {
  inherit pname version;

  src = fetchFromGitHub {
    owner = "iDvel";
    repo = "rime-ice";
    rev = version;
    hash = "sha256-TXe5dScOsyqMwKg03CDmhiSWLHV0QOKOyZGvfG4LFzY=";
  };

  # Can't have any 'custom' things, they should be in $XDG, uhho.
  patches = [ ./patches/rime-ice-taste.patch ];

  buildInputs = [ librime ];

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

  # TODO: use install -d...
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
