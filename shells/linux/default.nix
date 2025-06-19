{ lib, ... }:

let
  base =
    {
      config,
      pkgs,
      pkgsCross,
      ...
    }:
    {
      shellHooks = lib.mkIf config.cross [
        ''export CROSS_COMPILE="${pkgsCross.stdenv.cc.targetPrefix}"''
      ];

      make = {
        # Make my own version of some config:
        defconfig = ''
          ${pkgs.gnumake}/bin/make defconfig "$@"
          ./scripts/config \
            -d COMPAT \
            -e ISO9660_FS -e JOLIET -e ZISOFS \
            -e 9P_FS_POSIX_ACL \
            -d DEBUG_INFO_REDUCED -e DEBUG_INFO_BTF
        '';

        # TODO: make compile_commands.json
        compdb = ''exec ./scripts/clang-tools/gen_compile_commands.py "$@"'';

        modules = ''
          ${pkgs.gnumake}/bin/make modules
          exec ${pkgs.gnumake}/bin/make INSTALL_MOD_PATH="$PWD/debian" modules_install
        '';

        # Maybe work...
        qemu = ''
          source ${./qemu.sh} ${lib.elemAt (lib.splitString "-" config.target) 0} "$@"
        '';
      };

      depsBuildBuild = with pkgs; [
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
      ];
    };

  clang = {
    gcc.enable = false;
    clang = {
      enable = true;
      unwrapped = true;
    };
    shellHooks = [ ''export LLVM="1"'' ];
  };
in
{
  n9.shell.linux = lib.mkMerge [
    base
  ];

  # For macOS please use the clang one :)
  n9.shell."linux.clang" = lib.mkMerge [
    base
    clang
  ];

  n9.shell."linux.arm64" = lib.mkMerge [
    base
    {
      triplet = "aarch64-unknown-linux-gnu";
      shellHooks = [ "export ARCH=arm64" ];
    }
  ];

  n9.shell."linux.x86_64" = lib.mkMerge [
    base
    {
      triplet = "x86_64-unknown-linux-gnu";
      shellHooks = [ "export ARCH=x86" ];
    }
  ];

  # Just fancy.
  n9.shell.rust-for-linux = lib.mkMerge [
    base
    { rust.enable = true; }
    clang
  ];
}
