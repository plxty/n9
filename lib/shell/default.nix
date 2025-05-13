{
  config,
  n9,
  inputs,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.n9.shell;

  module = lib.types.submoduleWith {
    modules = [
      # options
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
        options.packages = lib.mkOption {
          type = lib.types.listOf lib.types.package;
          default = [ ];
        };

        # shorthand of shellHook:
        options.shellHook = lib.mkOption {
          type = lib.types.str;
          default = "";
        };

        options.passthru = n9.mkAttrsOption { };

        config._module.args.pkgsCross = import inputs.nixpkgs {
          inherit (pkgs) system;
          crossSystem.config = config.triplet;
        };
      }
      ./config/gcc.nix
      ./config/rust.nix
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

  # TODO: Better organize?
  options.drv = lib.mkOption {
    type = lib.types.attrsOf lib.types.package;
  };

  config.drv = lib.mapAttrs (
    name: config:
    (
      if pkgs.system == config.target then pkgs.mkShellNoCC else config._module.args.pkgsCross.mkShellNoCC
    )
      (
        {
          inherit name;
          inherit (config) shellHook;
          depsBuildBuild = config.packages;
        }
        // config.passthru
      )
  ) cfg;
}
