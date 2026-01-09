{ lib, ... }:

{
  n9.shell.gcc =
    { pkgs, ... }:
    {
      variant.shell.depsBuildBuild = with pkgs; [
        gettext
      ];

      environment.variables.LIBRARY_PATH = lib.makeLibraryPath (
        with pkgs;
        [
          glibc
        ]
      );

      # mkdir build && cd build
      # @see nixpkgs/pkgs/development/compilers/gcc/common/configure-flags.nix
      # @see https://discourse.nixos.org/t/development-on-gcc-on-nixos/18376
      environment.make.targets.configure = with pkgs; ''
        # resetting the dynamic linker:
        gcc_source="$(dirname "$DIRENV_FILE")"
        sed -i 's!"/lib64/!"${stdenv.cc.libc}/lib64/!' "$gcc_source/gcc/config/i386/linux64.h"

        # real configure:
        "$gcc_source/configure" \
          "--prefix=$PWD" \
          --enable-languages=c,c++ \
          --with-dwarf2 \
          --disable-multilib \
          "--with-gmp-include=${gmp.dev}/include" \
          "--with-gmp-lib=${gmp.out}/lib" \
          "--with-mpfr-include=${mpfr.dev}/include" \
          "--with-mpfr-lib=${mpfr.out}/lib" \
          "--with-mpc=${libmpc}" \
          --with-sysroot=/ \
          "--with-native-system-header-dir=${lib.getDev stdenv.cc.libc}/include"
      '';

      # no extra hardening:
      variant.shell.hardeningDisable = [
        "format"
      ];
    };
}
