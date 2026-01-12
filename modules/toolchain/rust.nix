{
  config,
  lib,
  pkgs,
  pkgsCross,
  inputs,
  ...
}:

let
  cfg = config.toolchain.rust;

  rust-bin = inputs.rust-overlay.lib.mkRustBin {
    # @see rust-overlay/docs/reference.md
    distRoot = "https://mirrors.tuna.tsinghua.edu.cn/rustup/dist";
  } pkgs;
in
{
  options.toolchain.rust = {
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
    # @see nixpkgs/doc/languages-frameworks/rust.section.md
    environment.packages = with pkgs; [
      rustPlatform.bindgenHook
    ];

    variant.shell.depsBuildBuild = with pkgs; [
      (rust-bin.${cfg.channel}.${cfg.version}.default.override {
        inherit (cfg) extensions;
        # nixpkgs/pkgs/build-support/rust/lib/default.nix
        targets = [ pkgsCross.stdenv.buildPlatform.rust.rustcTargetSpec ];
      })

      rust-bindgen
      cargo
    ];

    # TODO: .source = writeYAML
    deployment.file.".helix/languages.toml".text = lib.mkIf config.shell.cross ''
      [language-server.rust-analyzer]
      config = { cargo = { "target" = "${config.shell.triplet}" } }
    '';

    deployment.file.".cargo/config.toml".text = lib.mkMerge [
      (lib.mkIf config.shell.cross ''
        [build]
        target = "${config.shell.triplet}"
      '')

      (lib.mkIf (config.shell.cross || config.shell.static) ''
        [target.${config.shell.triplet}]
        ${lib.optionalString config.shell.cross
          # https://github.com/rust-lang/rust/issues/34282#issuecomment-796182029
          ''linker = "${config.shell.triplet}-gcc"''
        }
        ${lib.optionalString config.shell.static ''rustflags = ["-C", "target-feature=+crt-static"]''}
      '')
    ];
  };
}
