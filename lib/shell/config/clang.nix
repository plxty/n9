{
  config,
  lib,
  pkgs,
  pkgsCross,
  ...
}:

let
  cfg = config.clang;

  clangCross =
    if cfg.unwrapped then
      "${pkgsCross.clangStdenv.cc.cc}/bin/clang"
    else
      "${pkgsCross.clangStdenv.cc}/bin/${config.triplet}-clang";

  # LLVM cross compile is quite annoying, especially in Linux:
  # 1. The linux uses clang for both depsBuildBuild and depsBuildHost
  # 2. NixOS wrapped clang in stdenv for both cross and non-cross
  # 3. They can't coexists due to linux hardcoded the host clang and target
  #
  # The wrapped version of compiler will resolve the libraries in Nix correctly,
  # thus you can use and link them. The unwrapped version, on the contrast, has
  # no library support and can only build for bare-metal code.
  #
  # P.S. The stdenv.cc.cc is the unwrapped drv of compiler, use at risk.
  # P.P.S. GCC might still be imported...
  # TODO: Judge the --target if is current platform?
  clangWrapper = pkgs.writers.writeBashBin "clang" ''
    for __clang_arg in "$@"; do
      if [[ "$__clang_arg" == "--target="* ]]; then
        exec "${clangCross}" "$@"
      fi
    done
    exec "${pkgs.clangStdenv.cc}/bin/clang" "$@"
  '';
in
{
  options.clang = {
    enable = lib.mkEnableOption "clang";

    # Whether to use a unwrapped clang when cross compiling?
    unwrapped = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
  };

  config = lib.mkIf cfg.enable {
    depsBuildBuild = with pkgs; [
      clangWrapper # it's multi-target, altough nix don't like
      lld
      libllvm
    ];
  };
}
