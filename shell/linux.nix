{ pkgs, ... }:

let
  makeWrapper = pkgs.writers.writeBashBin "make" ''
    if [[ "$1" == "compdb" ]]; then
      shift 1
      set -xeu
      cd $(git rev-parse --show-toplevel)
      exec ./scripts/clang-tools/gen_compile_commands.py "$@"
    fi
    exec ${pkgs.gnumake}/bin/make "$@"
  '';

  depsBuildBuild = with pkgs; [
    makeWrapper
    flex
    bison
    ncurses
    elfutils
  ];
in
{
  n9.shell.linux = {
    shellHooks = [ ''export MAKEFLAGS="-j$(nproc --ignore 3)"'' ];
    inherit depsBuildBuild;
  };

  n9.shell."linux.arm64" = {
    # TODO: Merge target & triplet?
    target = "aarch64-linux";
    triplet = "aarch64-linux-gnu-gcc";
    shellHooks = [ ''export MAKEFLAGS="-j$(nproc --ignore 3)"'' ];
    inherit depsBuildBuild;
  };

  # Just fancy.
  n9.shell.rust-for-linux = {
    gcc.enable = false;
    clang.enable = true;
    rust.enable = true;
    shellHooks = [
      ''
        export MAKEFLAGS="-j$(nproc --ignore 3)"
        export LLVM="1"
      ''
    ];
    inherit depsBuildBuild;
  };
}
