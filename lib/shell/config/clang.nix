{
  config,
  lib,
  pkgs,
  pkgsCross,
  ...
}:

let
  cfg = config.clang;
  underscore = lib.replaceStrings [ "-" ] [ "_" ];

  # LLVM cross compile is quite annoying, especially in Linux:
  # 1. The linux uses clang for both depsBuildBuild and depsBuildHost
  # 2. NixOS wrapped clang in stdenv for both cross and non-cross
  # 3. They can't coexists due to linux hardcoded the host clang and target
  # Therefore we can only write a little wrapper to help us call the right
  # side of clang, kind of ugly :(
  # Other tools (e.g. lld) from host seems usable, only clang needs it.
  # P.S. The stdenv.cc.cc is the unwrapped drv of compiler, use at risk.
  # TODO: arm-linux-gnueabi
  clangWrapper = pkgs.writers.writeBashBin "clang" ''
    for __clang_arg in "$@"; do
      if [[ "$__clang_arg" == "--target=${config.target}" ]]; then
        exec ${pkgsCross.clangStdenv.cc}/bin/${config.target}-clang "$@"
      fi
    done
    exec ${pkgs.clangStdenv.cc}/bin/clang "$@"
  '';
in
{
  options.clang = {
    enable = lib.mkEnableOption "clang";
  };

  config = lib.mkIf cfg.enable {
    depsBuildBuild = lib.mkIf cfg.enable (
      with pkgs;
      [
        clangWrapper # it's multi-target, altough nix don't like
        lld
        libllvm
      ]
    );

    # TODO: Workaround for fatal errors:
    shellHook = lib.mkIf cfg.enable ''
      export NIX_CFLAGS_COMPILE+=" -Qunused-arguments"
      export NIX_CFLAGS_COMPILE_${underscore pkgs.stdenv.buildPlatform.config}+=" -Qunused-arguments"
      export NIX_CFLAGS_COMPILE_${underscore config.target}+=" -Qunused-arguments"
    '';
  };
}
