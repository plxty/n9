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

  shellHooks = [ ''export MAKEFLAGS="-j$(nproc --ignore 3)"'' ];

  depsBuildBuild = with pkgs; [
    makeWrapper
    flex
    bison
    ncurses
    elfutils
    openssl
  ];
in
{
  n9.shell.linux = {
    inherit shellHooks depsBuildBuild;
  };

  n9.shell."linux.arm64" = {
    triplet = "aarch64-unknown-linux-gnu";
    shellHooks = shellHooks ++ [ "export ARCH=arm64" ];
    inherit depsBuildBuild;
  };

  # For different config, it seems the nix will select the most suitable argument,
  # dynamically, with `config._module.args` as other options.
  n9.shell."linux.riscv" = {
    triplet = "riscv64-unknown-linux-gnu";
    shellHooks = shellHooks ++ [ "export ARCH=riscv" ];
  };

  # Just fancy.
  n9.shell.rust-for-linux = {
    gcc.enable = false;
    clang = {
      enable = true;
      unwrapped = true;
    };
    rust.enable = true;
    shellHooks = shellHooks ++ [ ''export LLVM="1"'' ];
    inherit depsBuildBuild;
  };
}
