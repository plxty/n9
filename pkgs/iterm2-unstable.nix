{
  lib,
  n9 ? import ../lib { inherit lib; },
  fetchurl,
  iterm2,
  unzip,
  ...
}:

let
  version = "3.6.7";
  version' = lib.replaceStrings [ "." ] [ "_" ] version;
  src = fetchurl {
    url = "https://iterm2.com/downloads/stable/iTerm2-${version'}.zip";
    sha256 = "sha256-4fCAGIijb/JrkW5PMgy94TBfPfC6d8LDaLujZ/7dfAI=";
  };
in
n9.assureVersion iterm2 version {
  inherit src;
  nativeBuildInputs = [ unzip ];
  unpackPhase = "unzip $src";
  sourceRoot = "iTerm.app"; # avoid /Applications/iTerm2.app/iTerm.app appears
}
