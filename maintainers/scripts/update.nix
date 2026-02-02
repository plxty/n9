# Fake nixpkgs, to satisfy nixpkgs-update...
# Although we've patched it for a "--local" option, but we still want to
# maintain some kind of "patchable" for in a little longer future :/

{
  # Impure!
  nixpkgs ? (import <nixpkgs> { }),
  pkgs ? nixpkgs.pkgs,
  # Copy of nixpkgs/maintainers/scripts/update.nix:
  package ? null, # --argstr package x,y,z
  nu ? false, # --arg nu true (nu stands for nixpkgs-update, produces UPDATE_INFO)
  ...
}:

let
  inherit (nixpkgs) lib;

  # Hacked nixpkgs-update:
  nixpkgs-update =
    lib.getExe
      (builtins.getFlake "github:plxty/nixpkgs-update").packages.${pkgs.stdenv.system}.default;

  # If update set, do only what user want to do:
  packages = import ../.. { inherit nixpkgs pkgs; };
  finalPackages =
    if package != null then lib.getAttrs (lib.splitString "," package) packages else packages;

  # TODO: Deal with dependency order? Seems not a matter now...
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

  # May get called by nixpkgs-update:
  updateScript = ''
    sed -E 's!(nixpkgs_root = ).+!\1"${nixpkgs.path}"!' "${nixpkgs.path}/maintainers/scripts/update.py" | \
      ${pkgs.python3.interpreter} /dev/stdin \
        "${json}" \
        --max-workers=1 \
        --order topological \
        --skip-prompt
  '';

  # Feeds to nixpkgs-update as param:
  # nix-shell maintainers/scripts/update.nix --arg nu true | \
  #   xargs -d '\0' nixpkgs-update update --local
  nuScript = ''
    while read -r pname attrPath hasUpdateScript oldVersion; do
      # TODO: More accurate way to test updateScript?
      if "$hasUpdateScript"; then
        "${nixpkgs-update}" update --local "$attrPath $oldVersion $oldVersion" || true
        continue
      fi

      if [[ "$oldVersion" == "" ]]; then
        # Maybe runCommand with no version?
        continue
      fi

      # Real hard work here, get from repology:
      newVersion="$(curl -s -H "User-Agent: https://github.com/plxty/n9" "https://repology.org/api/v1/project/$pname" | \
        jq -r '.[] | select(.status == "newest") | .version' | sort -Vr | head -1)"
      if [[ "$oldVersion" != "$newVersion" ]]; then
        "${nixpkgs-update}" update --local "$attrPath $oldVersion $newVersion" || true
      fi
    done < \
      <(jq -r '.[] | [.pname,.attrPath,if .updateScript != [""] then "true" else "false" end,.oldVersion] | join(" ")' "${json}")
  '';
in
pkgs.stdenv.mkDerivation {
  name = "nixpkgs-update-script";
  buildCommand = "exit 1";
  shellHook = ''
    unset shellHook
    set -uex
    cat "${json}"
    ${if !nu then updateScript else nuScript}
    exit $?
  '';
  nativeBuildInputs = with pkgs; [
    git
    nix
    cacert
    curl
    jq
  ];
}
