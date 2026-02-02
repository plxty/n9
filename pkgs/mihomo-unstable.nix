{
  lib,
  fetchFromGitHub,
  mihomo,
  ...
}:

let
  n9 = import ../lib {
    inherit lib;
    inputs = null;
  };

  version = "1.19.19";
  src = fetchFromGitHub {
    owner = "MetaCubeX";
    repo = "mihomo";
    tag = "v${version}";
    sha256 = "sha256-pyPVlVLJoqm/S/cRDSK/PPP58lmu8KBzDHE2we71ugs=";
  };
in
# buildGo, @see golangModuleVersion in nixpkgs-update:
n9.assureVersion mihomo version {
  inherit src;
  vendorHash = "sha256-xNga/f8GO+HItwAXX6XewCyTS7xtGpOBFv6RCgxI18Y=";
}
