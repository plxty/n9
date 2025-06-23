{
  config,
  lib,
  pkgs,
  n9,
  ...
}:

let
  cfg = config.golang;
in
{
  options.golang = {
    # TODO: try static?
    enable = lib.mkEnableOption "golang";

    version = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
    };
  };

  config = lib.mkIf cfg.enable {
    depsBuildBuild = with pkgs; [
      (if cfg.version == null then pkgs.go else pkgs."go_${cfg.version}")
      gopls
    ];

    shellHooks = lib.mkMerge [
      (lib.mkIf config.cross (
        let
          tuple = lib.splitString "-" config.target;
          arch = lib.elemAt tuple 0;
          arch' = n9.match arch {
            x86_64 = "amd64";
            aarch64 = "arm64";
          } arch;
          os = lib.elemAt tuple 1;
        in
        [
          ''
            export GOARCH="${arch'}"
            export GOOS="${os}"
          ''
        ]
      ))

      [ ''export GO111MODULE="on"'' ]
    ];
  };
}
