{
  n9,
  inputs,
  lib,
  pkgs,
  ...
}:

let
  essential =
    { config, ... }:
    {
      options.target = lib.mkOption {
        type = lib.types.str;
        default = pkgs.system;
      };

      options.triplet = lib.mkOption {
        type = lib.types.str;
        # TODO: examples.nix?
        default =
          if pkgs.system == "x86_64-linux" then
            "x86_64-unknown-linux-gnu"
          else if pkgs.system == "aarch64-linux" then
            "aarch64-unknown-linux-gnu"
          else
            abort "No match triplet of ${pkgs.system}";
      };

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

      config._module.args.pkgsCross = import inputs.nixpkgs {
        inherit (pkgs) system;
        crossSystem.config = config.triplet;
      };
    };

  drv =
    {
      config,
      name,
      pkgsCross,
      ...
    }:
    {
      config.drv = (if pkgs.system == config.target then pkgs.mkShellNoCC else pkgsCross.mkShellNoCC) {
        inherit name;
        inherit (config)
          depsBuildBuild
          packages
          buildInputs
          ;
        shellHook = lib.concatStringsSep "\n" config.shellHooks;
      };
    };

  module = lib.types.submoduleWith {
    modules = [
      # options
      essential
      ./config/gcc.nix
      ./config/clang.nix
      ./config/rust.nix

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
  };
in
{
  options.n9.shell = lib.mkOption {
    type = lib.types.attrsOf module;
    default = { };
  };
}
