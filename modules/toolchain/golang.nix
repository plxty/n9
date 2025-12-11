{
  config,
  lib,
  pkgs,
  pkgsCross,
  ...
}:

let
  cfg = config.toolchain.golang;
in
{
  options.toolchain.golang = {
    enable = lib.mkEnableOption "golang";

    version = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
    };

    # TODO: Warning about setting version + package together?
    package = lib.mkOption {
      type = lib.types.package;
      default = if cfg.version == null then pkgs.go else pkgs."go_${cfg.version}";
    };
  };

  config.environment.variables = lib.mkMerge [
    (lib.mkIf config.shell.cross {
      inherit (pkgsCross.stdenv.buildPlatform.go) GOOS GOARCH;
    })

    { GO111MODULE = "on"; }
  ];

  config.variant.shell.depsBuildBuild = lib.mkIf cfg.enable [
    cfg.package
    pkgs.gopls
  ];
}
