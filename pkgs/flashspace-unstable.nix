{
  lib,
  n9 ? import ../lib { inherit lib; },
  fetchurl,
  flashspace,
  unzip,
  ...
}:

let
  version = "4.15.71";
  src = fetchurl {
    url = "https://github.com/wojciech-kulik/FlashSpace/releases/download/v${version}/FlashSpace.app.zip";
    sha256 = "sha256-bXlgz94S6JNNVZCmeqvIBNEZeMrTjLsJe7B/FVcuVOo=";
  };
in
n9.assureVersion flashspace version {
  inherit src;
  nativeBuildInputs = [ unzip ];
  unpackPhase = "unzip $src";
  sourceRoot = "flashspace.app";
}
