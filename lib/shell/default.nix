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
            aarch64-unknown-linux-musl = "aarch64-linux";
            aarch64-linux-gnu = "aarch64-linux";
            riscv64-unknown-linux-gnu = "riscv64-linux";
            arm64-apple-darwin = "aarch64-darwin";
          } null;
        in
        lib.trace "shell: selecting ${target} for ${name}" target;

      # for shorthand: also treat as cross compile if not gnu, i.e. musl.
      options.cross = lib.mkEnableOption "cross";
      config.cross = pkgs.stdenv.buildPlatform.config != config.triplet;

      # shorthand of depsBuildBuild:
      # https://nixos.org/manual/nixpkgs/stable/#variables-specifying-dependencies
      options.depsBuildBuild = lib.mkOption {
        type = lib.types.listOf lib.types.package;
        default = [ ];
      };

      # shorthand of packages (@see nixpkgs/pkgs/build-support/mkshell/default.nix),
      # the alias of nativeBuildInputs (depsBuildHost):
      # In most non-compiler case (where you can build a aarch64-gcc, which runs
      # on riscv64, with builder in x86_64, in this case build=x86_64, host=riscv64,
      # target=aarch64), build eq. to host, therefore the depsBuildHost will have
      # the same effect of depsBuildBuild or depsHostHost.
      #
      # however, there's one major difference for dpesBuildBuild and depsBuildHost,
      # is that packages in the depsBuildHost will exposed to depsBuildBuild.
      options.packages = lib.mkOption {
        type = lib.types.listOf lib.types.package;
        default = [ ];
      };

      # shorthand of depsHostHost:
      options.depsHostHost = lib.mkOption {
        type = lib.types.listOf lib.types.package;
        default = [ ];
      };

      # shorthand of buildInputs (depsHostTarget):
      # Here's what you really want to put target libraries (and headers).
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
          depsHostHost
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
