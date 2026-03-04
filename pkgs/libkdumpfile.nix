{
  stdenv,
  fetchzip,
  zlib,
  lzo,
  snappy,
  zstd,
  libbfd,
  ...
}:

let
  version = "0.5.6";
  src = fetchzip {
    url = "https://codeberg.org/ptesarik/libkdumpfile/releases/download/v${version}/libkdumpfile-${version}.tar.gz";
    sha256 = "1dm5917b5942j62z7n0hvbrk8nz53p4xf0n58x1adz3x4dpw14w1";
  };
in
stdenv.mkDerivation {
  pname = "libkdumpfile";
  inherit version src;

  buildInputs = [
    zlib
    lzo
    snappy
    zstd
    libbfd
  ];
}
