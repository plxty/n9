{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.environment.make;
in
{
  options.environment.make = {
    targets = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = { };
    };

    flags = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
    };

    extra = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
    };
  };

  config.variant.shell.depsBuildBuild =
    let
      make = pkgs.writers.writeBashBin "make" (
        lib.concatStringsSep "\n" (
          [
            ''
              function make() {
                "${lib.getExe pkgs.gnumake}" ${lib.concatStringsSep " " cfg.flags} "$@"
              }
            ''
            (lib.optionalString (cfg.extra != null) cfg.extra)
          ]
          ++ (lib.mapAttrsToList (name: value: ''
            if [[ "$1" == "${name}" ]]; then
              shift 1
              set -uex
              ${value}
              exit $?
            fi
          '') cfg.targets)
          ++ [
            ''
              make "$@"
            ''
          ]
        )
      );
    in
    lib.mkIf (cfg.targets != { } || cfg.flags != [ ] || cfg.extra != null) (lib.mkBefore [ make ]);
}
