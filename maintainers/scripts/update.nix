# Fake nixpkgs, to satisfy nixpkgs-update...
# Although we've patched it for a "--local" option, but we still want to
# maintain some kind of "patchable" for in a little longer future :/

{
  # Impure!
  nixpkgs ? (import <nixpkgs> { }),
  pkgs ? nixpkgs.pkgs,
  # Copy of nixpkgs/maintainers/scripts/update.nix:
  package ? null, # --argstr package x,y,z
  ...
}:

let
  inherit (nixpkgs) lib;

  # If update set, do only what user want to do:
  packages = import ../.. { inherit nixpkgs pkgs; };
  finalPackages =
    if package != null then lib.getAttrs (lib.splitString "," package) packages else packages;

  get-script = pkg: pkg.updateScript or null;
  packageData =
    attrPath: package:
    let
      updateScript = get-script package;
    in
    {
      name = package.name;
      pname = lib.getName package;
      oldVersion = lib.getVersion package;
      updateScript = map toString (lib.toList (updateScript.command or updateScript));
      supportedFeatures = updateScript.supportedFeatures or [ ];
      attrPath = updateScript.attrPath or attrPath;
    };
  json = pkgs.writeText "packages.json" (
    builtins.toJSON (lib.mapAttrsToList packageData finalPackages)
  );
in
pkgs.stdenv.mkDerivation {
  name = "nixpkgs-update-script";
  buildCommand = "exit 1";
  shellHook = ''
    set -uex
    unset shellHook
    cat "${json}" && echo # for debug
    sed -E 's!(nixpkgs_root = ).+!\1"${nixpkgs.path}"!' "${nixpkgs.path}/maintainers/scripts/update.py" | \
      ${pkgs.python3.interpreter} /dev/stdin \
        "${json}" \
        --max-workers=1 \
        --order topological \
        --skip-prompt
    exit $?
  '';
  nativeBuildInputs = with pkgs; [
    git
    nix
    cacert
  ];
}
