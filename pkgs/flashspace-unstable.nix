{
  lib,
  n9 ? import ../lib { inherit lib; },
  fetchurl,
  flashspace,
  unzip,
  ...
}:

let
  version = "4.15.70";
  src = fetchurl {
    url = "https://github.com/wojciech-kulik/FlashSpace/releases/download/v${version}/FlashSpace.app.zip";
    sha256 = "sha256-VD469l6rBTWR+b48PDbZgfp8ywDcr1uLqxDSVgzgb7U=";
  };
in
n9.assureVersion flashspace version {
  inherit src;
  nativeBuildInputs = [ unzip ];
  unpackPhase = "unzip $src";
  sourceRoot = "flashspace.app";
}
