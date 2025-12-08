{
  n9,
  writers,
  python3Packages,
  git,
  ...
}:

let
  src = n9.sources.gitcache;

  gitcache = python3Packages.buildPythonPackage {
    pname = "gitcache";
    inherit src;
    inherit (src) version;
    pyproject = true;

    build-system = with python3Packages; [
      setuptools
      wheel
    ];

    dependencies = with python3Packages; [
      portalocker
      pytimeparse
      coloredlogs
    ];
  };
in
# TODO: wrapper of wrapper?
writers.writeBashBin "gitcache" ''
  export GITCACHE_REAL_GIT="${git}/bin/git"
  exec "${gitcache}/bin/gitcache" "$@"
''
