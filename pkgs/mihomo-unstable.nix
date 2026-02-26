{
  lib,
  n9 ? import ../lib { inherit lib; },
  fetchFromGitHub,
  mihomo,
  ...
}:

let
  version = "1.19.20";
  src = fetchFromGitHub {
    owner = "MetaCubeX";
    repo = "mihomo";
    tag = "v${version}";
    sha256 = "sha256-w1W8zClaiHA0EdAm4sf8Va11pxjXFFwmnSUyb7UWd74=";
  };
in
# buildGo, @see golangModuleVersion in nixpkgs-update:
n9.assureVersion mihomo version {
  inherit src;
  vendorHash = "sha256-MrHUkwBxGgmKPsTXFM32q8PyXmHJiFvSwFmxRA1kdZM=";
}
