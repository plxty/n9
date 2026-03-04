{
  buildNpmPackage,
  fetchFromGitHub,
  unstableGitUpdater,
  ...
}:

let
  version = "0-unstable-2025-08-24";
  src = fetchFromGitHub {
    owner = "nickgnd";
    repo = "tmux-mcp";
    rev = "ec68b1061cf3b0d1faa9c5ef5e3f703918e07ba8";
    sha256 = "sha256-rZhVjuWRlVSjLthgSKbfuPpQQKP9YC2Pjun/6JQYUo0=";
  };
in
buildNpmPackage {
  pname = "tmux-mcp";
  inherit version src;
  npmDepsHash = "sha256-N1j8yBC1zQiUTnpfVw2ppY2kh4kJvT88kpTlB1kCBKY=";

  passthru.updateScript = unstableGitUpdater { hardcodeZeroVersion = true; };
}
