{
  fetchurl,
  fetchFromGitHub,
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

python3Packages.buildPythonPackage rec {
  pname = "drgn";
  version = "0.0.33";
  src = fetchFromGitHub {
    owner = "osandov";
    repo = "drgn";
    tag = "v${version}";
    sha256 = "09bp6fwyni5ycllaava98zsf334sivk9q74yl5vspwkp5ajpjj5q";
  };
  pyproject = true;

  patches = [
    # Enable the builtin commands (%crash), it still unstable, and lacks of many things, just try.
    (fetchurl {
      url = "https://github.com/osandov/drgn/commit/6cff072db547f6562505939a776e8260abe3f683.patch";
      sha256 = "1vj6616h0f9a2iy812ak2clzc4jqqrl6lfzs3pmk12acl3z1rjs7";
    })
  ];

  # Legacy needs:
  build-system = with python3Packages; [
    setuptools
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
