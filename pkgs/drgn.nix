{
  n9,
  fetchurl,
  python3Packages,
  automake,
  autoconf,
  libtool,
  gnumake,
  pkg-config,
  elfutils,
  libdwarf,
  libkdumpfile,
  xz,
  ...
}:

let
  src = n9.sources.drgn;
in
python3Packages.buildPythonPackage {
  pname = "drgn";
  inherit src;
  inherit (src) version;

  patches = [
    # Enable the builtin commands (%crash), it still unstable, and lacks of many things, just try.
    (fetchurl {
      url = "https://github.com/osandov/drgn/commit/6cff072db547f6562505939a776e8260abe3f683.patch";
      sha256 = "1vj6616h0f9a2iy812ak2clzc4jqqrl6lfzs3pmk12acl3z1rjs7";
    })
  ];

  # TODO: Something to nativeBuildInputs?
  depsBuildBuild = [
    automake
    autoconf
    libtool
    gnumake
  ];

  nativeBuildInputs = [
    pkg-config
  ];

  buildInputs = [
    elfutils
    libdwarf
    libkdumpfile
    xz
  ];
}
