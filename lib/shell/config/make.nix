{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.make;
in
{
  options.make = lib.mkOption {
    type = lib.types.attrsOf lib.types.str;
    default = { };
  };

  config = lib.mkIf (cfg != { }) {
    depsBuildBuild = lib.mkBefore [
      (pkgs.writers.writeBashBin "make" (
        lib.concatStringsSep "\n" (
          (lib.mapAttrsToList (name: value: ''
            if [[ "$1" == "${name}" ]]; then
              shift 1
              set -uex
              ${value}
              exit $?
            fi
          '') cfg)
          ++ [ ''exec "${pkgs.gnumake}/bin/make" "$@"'' ]
        )
      ))
    ];
  };
}
