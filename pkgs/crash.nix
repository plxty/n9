{
  lib,
  stdenv,
  fetchFromGitHub,
  fetchurl,
  bison,
  texinfo,
  gmp,
  mpfr,
  zlib,
  ncurses,
  ...
}:

let
  # TODO: make CROSS_COMPILE
  pname = "crash";
  version = "9.0.0";

  gdb = rec {
    version = "16.2";
    filename = "gdb-${version}.tar.gz";
    src = fetchurl {
      url = "https://mirrors.tuna.tsinghua.edu.cn/gnu/gdb/${filename}";
      hash = "sha256-vcHaSgMygKx1Ln00sEGO+qRb7QkyNcuI5i6pYXUqN/g=";
    };
  };
in
stdenv.mkDerivation {
  inherit pname version;

  src = fetchFromGitHub {
    owner = "crash-utility";
    repo = "crash";
    rev = version;
    hash = "sha256-GSqlaBa+rSzxE2wgXTs542K9gUFtnvA14XeC6Auo4NA=";
  };

  # satisfy the "make gdb_unzip":
  postUnpack = ''
    cp "${gdb.src}" "$sourceRoot/${gdb.filename}"
  '';

  # Just run make, the crash handles the configure phase.
  dontConfigure = true;
  enableParallelBuilding = true;

  # Test must fail.
  doCheck = false;

  # @see nixpkgs/pkgs/development/tools/misc/gdb/default.nix
  nativeBuildInputs = [
    bison
    texinfo
  ];

  buildInputs = [
    gmp
    mpfr
    zlib
    ncurses
  ];

  meta = {
    homepage = "https://crash-utility.github.io";
    license = with lib.licenses; [ gpl3Plus ];
  };
}
