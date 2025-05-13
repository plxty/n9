{
  config,
  lib,
  n9,
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

  config.depsBuildBuild = lib.mkIf cfg.enable (
    with pkgs;
    [
      (rust.rust-bin.${cfg.channel}.${cfg.version}.default.override {
        inherit (cfg) extensions;
        # https://doc.rust-lang.org/beta/rustc/platform-support.html
        # Adjust some of the triplets... TODO: Better idea? Triplet of Rust and
        # GCC isn't always the same... No idea of how to match them at once.
        # Maybe add a new rust.triplet option?
        targets = [
          (n9.match {
            "x86_64-linux-gnu" = "x86_64-unknown-linux-gnu";
            "aarch64-linux-gnu" = "aarch64-unknown-linux-gnu";
          } config.triplet config.triplet)
        ];
      })
      rust-bindgen
      cargo
    ]
  );
}
