{
  n9,
  stdenv,
  zlib,
  lzo,
  snappy,
  zstd,
  libbfd,
  ...
}:

let
  src = n9.sources.libkdumpfile;
in
stdenv.mkDerivation {
  pname = "libkdumpfile";
  inherit src;
  inherit (src) version;

  buildInputs = [
    zlib
    lzo
    snappy
    zstd
    libbfd
  ];
}
