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
  isDarwinCross = pkgs.stdenv.isDarwin && (pkgs.system != config.target);
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
      default = [
        "rust-src"
        "rust-analyzer"
      ];
    };
  };

  config = lib.mkIf cfg.enable {
    depsBuildBuild = with pkgs; [
      (rust.rust-bin.${cfg.channel}.${cfg.version}.default.override {
        inherit (cfg) extensions;
        # https://doc.rust-lang.org/beta/rustc/platform-support.html
        # Adjust some of the triplets... TODO: Better idea? Triplet of Rust and
        # GCC isn't always the same... No idea of how to match them at once.
        # Maybe add a new rust.triplet option?
        targets = [
          (n9.match config.triplet {
            "x86_64-linux-gnu" = "x86_64-unknown-linux-gnu";
            "aarch64-linux-gnu" = "aarch64-unknown-linux-gnu";
            "arm64-apple-darwin" = "aarch64-apple-darwin";
          } config.triplet)
        ];
      })
      rust-bindgen
      cargo
    ];

    # Needed for cross, "cargo build --target=...":
    gcc.enable = lib.mkIf isDarwinCross (
      lib.mkForce (lib.trace "rust with cross compile (on darwin) must enable gcc" true)
    );

    shellHooks = lib.optionals isDarwinCross [
      # https://github.com/rust-lang/rust/issues/34282#issuecomment-796182029
      ''
        mkdir -p .cargo
        {
          echo "[build]"
          echo 'target = "${config.triplet}"'
          echo ""
          echo "[target.${config.triplet}]"
          echo 'linker = "${config.triplet}-gcc"'
        } > .cargo/config.toml
      ''

      # To config it automatically:
      ''
        mkdir -p .helix
        {
          echo "[language-server.rust-analyzer]"
          echo "config = { cargo = { \"target\" = \"${config.triplet}\" } }"
        } > .helix/languages.toml
      ''
    ];
  };
}
