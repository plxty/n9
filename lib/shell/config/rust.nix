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
  isStatic =
    (
      if (cfg.static && !(lib.hasSuffix "-musl" config.triplet)) then
        lib.trace "rust static is better well played with musl-c, glibc may cause issues"
      else
        lib.id
    )
      cfg.static;
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

    # https://doc.rust-lang.org/reference/linkage.html#static-and-dynamic-c-runtimes
    static = lib.mkEnableOption "static";
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

    shellHooks = lib.mkMerge [
      [
        # If target changed, refresh the environment
        ''
          if [[ ! -f .direnv/rust-target || "$(< .direnv/rust-target)" != "${config.triplet}" ]]
          then
            rm -f .cargo/config.toml .helix/languages.toml
            echo "${config.triplet}" > .direnv/rust-target
          fi
        ''
      ]

      (lib.mkIf (config.cross || isStatic) [
        ''
          if [[ ! -f .cargo/config.toml ]]; then
            mkdir -p .cargo
            {
              ${lib.optionalString config.cross ''
                echo "[build]"
                echo 'target = "${config.triplet}"'
                echo ""
              ''}
              echo '[target.${config.triplet}]'
              ${lib.optionalString config.cross
                # https://github.com/rust-lang/rust/issues/34282#issuecomment-796182029
                ''
                  echo 'linker = "${config.triplet}-gcc"'
                ''
              }
              ${lib.optionalString isStatic ''
                echo 'rustflags = ["-C", "target-feature=+crt-static"]''\'
              ''}
            } > .cargo/config.toml
          fi
        ''
      ])

      (lib.mkIf config.cross [
        ''
          if [[ ! -f .helix/languages.toml ]]; then
            mkdir -p .helix
            {
              echo "[language-server.rust-analyzer]"
              echo 'config = { cargo = { "target" = "${config.triplet}" } }'
            } > .helix/languages.toml
          fi
        ''
      ])
    ];
  };
}
