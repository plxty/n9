{
  n9,
  inputs,
  lib,
  pkgs,
  ...
}@args:

shells:

let
  essential =
    { name, config, ... }:
    {
      options.target = lib.mkOption {
        type = lib.types.str;
      };

      options.triplet = lib.mkOption {
        type = lib.types.str;
        # TODO: examples.nix?
        default = pkgs.stdenv.buildPlatform.config;
      };

      # choose target from triplet:
      config.target =
        let
          target = n9.match config.triplet {
            x86_64-unknown-linux-gnu = "x86_64-linux";
            x86_64-unknown-linux-musl = "x86_64-linux";
            x86_64-unknown-none = "x86_64-linux";
            x86_64-linux-gnu = "x86_64-linux";
            aarch64-unknown-linux-gnu = "aarch64-linux";
            aarch64-linux-gnu = "aarch64-linux";
            riscv64-unknown-linux-gnu = "riscv64-linux";
            arm64-apple-darwin = "aarch64-darwin";
          } null;
        in
        lib.trace "shell: selecting ${target} for ${name}" target;

      # for shorthand:
      options.cross = lib.mkEnableOption "cross";
      config.cross = pkgs.system != config.target;

      # shorthand of depsBuildBuild:
      options.depsBuildBuild = lib.mkOption {
        type = lib.types.listOf lib.types.package;
        default = [ ];
      };

      # shorthand of packages (@see nixpkgs/pkgs/build-support/mkshell/default.nix),
      # the alias of nativeBuildInputs:
      options.packages = lib.mkOption {
        type = lib.types.listOf lib.types.package;
        default = [ ];
      };

      # shorthand of buildInputs:
      options.buildInputs = lib.mkOption {
        type = lib.types.listOf lib.types.package;
        default = [ ];
      };

      # shorthand of shellHook:
      options.shellHooks = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
      };

      # TODO: Better organize?
      options.drv = lib.mkOption {
        type = lib.types.package;
      };

      config._module.args.pkgsCross =
        if config.cross then n9.mkCrossNixpkgs inputs.nixpkgs pkgs.system config.triplet else pkgs;
    };

  drv =
    {
      config,
      name,
      pkgsCross,
      ...
    }:
    let
      mkShellNoCC =
        if (!config.gcc.enable && config.clang.enable) then
          # prefer to use the clang env, it makes clang detects the build inputs.
          lib.trace "shell: selecting clang stdenv" (
            pkgsCross.mkShellNoCC.override { stdenv = pkgsCross.clangStdenvNoCC; }
          )
        else
          lib.trace "shell: selecting default stdenv" pkgsCross.mkShellNoCC;
    in
    {
      config.drv = mkShellNoCC {
        inherit name;
        inherit (config)
          depsBuildBuild
          packages
          buildInputs
          ;
        shellHook = lib.concatStringsSep "\n" (
          [
            # The mkShellNoCC still exports CC/AR/..., we'd better unset them.
            # @see nixpkgs/pkgs/build-support/cc-wrapper/setup-hooks.sh
            ''
              export -n \
                AR AR_FOR_BUILD \
                AS AS_FOR_BUILD \
                CC CC_FOR_BUILD \
                CXX CXX_FOR_BUILD \
                LD LD_FOR_BUILD \
                NM NM_FOR_BUILD \
                OBJCOPY OBJCOPY_FOR_BUILD \
                OBJDUMP OBJDUMP_FOR_BUILD \
                PKG_CONFIG PKG_CONFIG_FOR_BUILD \
                RANLIB RANLIB_FOR_BUILD \
                READELF READELF_FOR_BUILD \
                SIZE SIZE_FOR_BUILD \
                STRINGS STRINGS_FOR_BUILD \
                STRIP STRIP_FOR_BUILD
            ''
          ]
          ++ config.shellHooks
        );
      };
    };
in
lib.mapAttrs (_: cfg: cfg.drv)
  (lib.evalModules {
    modules = [
      {
        options.n9.shell = lib.mkOption {
          type = lib.types.attrsOf (
            lib.types.submoduleWith {
              modules = [
                # modules
                essential
                ./config/make.nix
                ./config/gcc.nix
                ./config/clang.nix
                ./config/rust.nix
                ./config/tex.nix

                # config
                drv
              ];
              specialArgs = {
                inherit
                  n9
                  inputs
                  lib
                  pkgs
                  ;
              };
            }
          );
          default = { };
        };
      }
    ] ++ shells;
    specialArgs = args;
  }).config.n9.shell
