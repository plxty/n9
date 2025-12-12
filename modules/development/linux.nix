{
  config,
  lib,
  pkgs,
  pkgsCross,
  ...
}:

let
  cfg = config.development.linux;

  withClang = {
    toolchain.gcc.enable = false;
    toolchain.clang.unwrapped = true;
    environment.variables.LLVM = "1";
  };
in
{
  options.development.linux = {
    enable = lib.mkEnableOption "linux";

    # To reduce dependencies requirement, by not making tools:
    kernel-only = lib.mkEnableOption "kernel-only";
  };

  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      {
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

        environment.packages = lib.mkIf (!cfg.kernel-only) (
          with pkgsCross;
          [
            # bpftool
            libllvm
            libcap
            libbfd
            # perf
            libtraceevent
          ]
        );

        # We're in development, so fine. @see nix-support/add-hardening.sh
        variant.shell.hardeningDisable = lib.mkIf (!cfg.kernel-only) [
          # selftests
          "fortify"
          # bpf, @see bpftune
          "stackprotector"
          "zerocallusedregs"
        ];

        environment.variables = {
          # Suppress all clang warnings about the target bpf:
          # For selftests, it's more recommend to compile them in the guest (debian or else).
          NIX_CC_WRAPPER_SUPPRESS_TARGET_WARNING = "1";
        };
      }
      (lib.mkIf config.toolchain.clang.enable withClang)
      (lib.mkIf (!config.toolchain.clang.enable && !cfg.kernel-only) {
        # For non-clang, and we have some bpf targets, which needs the clang.
        # We need the wrapped version, as some bpf.h we still need.
        variant.shell.depsBuildBuild = with pkgs; [
          (writers.writeBashBin "clang" ''
            # TODO: Better way to filter out hardens for bpf? To make a clang-bpf?
            # Or wrapper it in our own customized toolchain.clang, make it cross?
            exec "${clang}" "$@" -Qunused-arguments
          '')
        ];
      })
    ]
  );
}
