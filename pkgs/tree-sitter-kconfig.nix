{
  stdenv,
  fetchFromGitHub,
  unstableGitUpdater,
  ...
}:

let
  src = fetchFromGitHub {
    owner = "tree-sitter-grammars";
    repo = "tree-sitter-kconfig";
    rev = "9ac99fe4c0c27a35dc6f757cef534c646e944881";
    hash = "sha256-8gZZLGL7giVHQIirjUIfsx3scP1L1VTFIZX7QOyjWvk=";
  };
in
stdenv.mkDerivation {
  pname = "tree-sitter-kconfig";
  inherit src;
  version = "0-unstable-2024-12-22";

  # Build it:
  makeFlags = [ "PREFIX=$(out)" ];
  postInstall = ''cp -r "${src}/queries" "$out/"'';

  passthru.updateScript = unstableGitUpdater { hardcodeZeroVersion = true; };
}
