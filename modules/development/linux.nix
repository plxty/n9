{
  config,
  lib,
  pkgs,
  pkgsCross,
  ...
}:

let
  cfg = config.development.linux;

  base = {
    variant.shell.depsBuildBuild = with pkgs; [
      perl
      flex
      bison
      ncurses
      openssl
      elfutils
      pahole
      cdrkit
      zlib
      kmod
      qemu
      virtme-ng
      drgn
      docutils
    ];

    environment.packages = with pkgsCross; [
      # bpftool requires
      libllvm
      libcap
      libbfd
    ];

    # We're in development, so fine.
    variant.shell.hardeningDisable = [
      "fortify" # for some selftests
      "stackprotector" # for bpf, @see bpftune
      "zerocallusedregs" # for bpf
    ];

    # Suppress all clang warnings about the target bpf:
    # For selftests, it's more recommend to compile them in the guest (debian or else).
    environment.variables.NIX_CC_WRAPPER_SUPPRESS_TARGET_WARNING = "1";
  };

  withClang = {
    toolchain.gcc.enable = false;
    toolchain.clang.unwrapped = true;
    environment.variables.LLVM = "1";
  };
in
{
  options.development.linux.enable = lib.mkEnableOption "linux";

  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      base
      (lib.mkIf config.toolchain.clang.enable withClang)
      (lib.mkIf (!config.toolchain.clang.enable) {
        # For non-clang, and we have some bpf targets, which needs the clang.
        # We need the wrapped version, as some bpf.h we still need.
        variant.shell.depsBuildBuild = with pkgs; [ clang ];
      })
    ]
  );
}
