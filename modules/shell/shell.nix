{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

let
  # n9.shell.<shell>.shell
  cfg = config.shell;
in
{
  options.shell = {
    triplet = lib.mkOption {
      type = lib.types.str;
      default =
        let
          # TODO: nixpkgs/lib/systems/examples.nix?
          host = pkgs.stdenv.buildPlatform.config;
          tryMusl = if lib.hasSuffix "-linux-gnu" host then "${lib.removeSuffix "-gnu" host}-musl" else host;
        in
        if cfg.static then tryMusl else host;
      apply =
        v:
        if (cfg.static && !(lib.hasSuffix "-musl" v)) then
          lib.trace "shell: static is better with -musl (instead of ${v}), glibc may cause issues" v
        else
          lib.trace "shell: selecting triplet ${v}" v;
    };

    # for shorthand: also treat as cross compile if not gnu, i.e. musl.
    cross = lib.mkOption {
      type = lib.types.bool;
      default = pkgs.stdenv.buildPlatform.config != cfg.triplet;
    };

    # for shorthand: doesn't do anything
    static = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };

    mkShell = lib.mkOption {
      type = lib.types.functionTo lib.types.package;
      default =
        let
          inherit (config._module.args) pkgsCross;
        in
        if (!config.toolchain.gcc.enable && !config.toolchain.clang.enable) then
          lib.trace "shell: selecting nocc stdenv" pkgsCross.mkShellNoCC
        else if (!config.toolchain.gcc.enable) then
          # prefer to use the clang env, it makes clang detects the build inputs.
          lib.trace "shell: selecting clang stdenv" (
            pkgsCross.mkShell.override { stdenv = pkgsCross.clangStdenv; }
          )
        else
          lib.trace "shell: selecting default stdenv" pkgsCross.mkShell;
    };
  };

  # Avail in other modules as well, TODO: submodule?
  config._module.args.pkgsCross =
    if cfg.cross then
      import inputs.nixpkgs {
        inherit (pkgs) overlays;
        inherit (pkgs.stdenv) system;
        crossSystem.config = cfg.triplet;
      }
    else
      pkgs;
}
