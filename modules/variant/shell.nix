{
  name,
  config,
  lib,
  ...
}:

let
  cfg = config.variant.shell;

  isShell = config.variant.get.current == "shell";
in
{
  options.variant.shell = {
    # shorthand of depsBuildBuild:
    # https://nixos.org/manual/nixpkgs/stable/#variables-specifying-dependencies
    depsBuildBuild = lib.mkOption {
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
    packages = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = [ ];
    };

    # shorthand of depsHostHost:
    depsHostHost = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = [ ];
    };

    # shorthand of buildInputs (depsHostTarget):
    # Here's what you really want to put target libraries (and headers).
    buildInputs = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = [ ];
    };

    # shorthand of shellHook:
    # TODO: Rename to hooks.
    shellHooks = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
    };

    hardeningDisable = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
    };
  };

  config.variant.get.build = lib.mkIf isShell (
    config.shell.mkShell {
      inherit name;
      inherit (cfg)
        depsBuildBuild
        packages
        depsHostHost
        buildInputs
        hardeningDisable
        ;
      shellHook = lib.concatStringsSep "\n" cfg.shellHooks;
    }
  );
}
