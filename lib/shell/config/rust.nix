{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

let
  cfg = config.rust;
  rust = pkgs.extend inputs.rust-overlay.overlays.default;
in
{
  options.rust = {
    enable = lib.mkEnableOption "rust";

    channel = lib.mkOption {
      type = lib.types.str;
      default = "stable";
    };

    version = lib.mkOption {
      type = lib.types.str;
      default = "latest";
    };

    extensions = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
    };
  };

  config.passthru = lib.mkIf cfg.enable {
    # Tools in host (like packages):
    depsBuildBuild = with pkgs; [
      (rust.rust-bin.${cfg.channel}.${cfg.version}.default.override {
        inherit (cfg) extensions;
        targets = [ config.triplet ];
      })
      rust-bindgen
      cargo
    ];
  };
}
