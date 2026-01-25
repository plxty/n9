{
  stdenv,
  fetchzip,
  zlib,
  lzo,
  snappy,
  zstd,
  libbfd,
  nix-update-script,
  ...
}:

stdenv.mkDerivation {
  pname = "libkdumpfile";
  src = fetchzip {
    url = "https://codeberg.org/ptesarik/libkdumpfile/releases/download/v0.5.6/libkdumpfile-0.5.6.tar.gz";
    sha256 = "1dm5917b5942j62z7n0hvbrk8nz53p4xf0n58x1adz3x4dpw14w1";
  };
  version = "0.5.6";

  buildInputs = [
    zlib
    lzo
    snappy
    zstd
    libbfd
  ];

  passthru.updateScript = nix-update-script { };
}
