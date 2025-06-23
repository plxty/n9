{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.golang;
in
{
  options.golang = {
    enable = lib.mkEnableOption "golang";

    version = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
    };
  };

  config = lib.mkIf cfg.enable {
    depsBuildBuild = with pkgs; [
      (if cfg.version == null then go else pkgs."go_${cfg.version}")
      gopls
    ];

    # TODO: cross with "GOOS" and "GOARCH" exports.
    shellHooks = [ ];
  };
}
