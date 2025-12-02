{
  n9,
  inputs,
  writers,
  python3,
  python3Packages,
  git,
  ...
}:

let
  src = n9.sources.gitcache;

  pyproject = inputs.pyproject-nix.lib.project.loadPyproject {
    projectRoot = "${src}";
  };

  pyattrs = pyproject.renderers.buildPythonPackage { python = python3; };

  gitcache = python3Packages.buildPythonPackage (
    pyattrs
    // {
      pname = "gitcache";
      inherit (src) version;
    }
  );
in
# TODO: wrapper of wrapper?
writers.writeBashBin "gitcache" ''
  export GITCACHE_REAL_GIT="${git}/bin/git"
  exec "${gitcache}/bin/gitcache" "$@"
''
