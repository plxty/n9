{
  # We're using GCC to compile, correct?
  # The built clang is a unwrapped compiler, and using it in pure NixOS might
  # be too complex, TODO: wrappers?
  n9.shell.llvm =
    { config, pkgs, ... }:
    let
      inherit (config.shell) triplet;
      inherit (pkgs.stdenv.cc) cc;

      # Merge all required gcc libraries to one place, for --gcc-install-dir:
      # TODO: How nix resolves this?
      gccInstall = pkgs.runCommand "gcc-install-dir" { } ''
        mkdir "$out"
        cp -r \
          "${cc}/lib/gcc/${triplet}/${cc.version}/." \
          "${pkgs.glibc}/lib/"{Scrt1.o,crti.o,crtn.o} \
          "${pkgs.libgcc}/lib/libgcc_s.so"* \
          "$out"
      '';
    in
    {
      # TODO: Make environment.packages points to here:
      variant.shell.depsBuildBuild = with pkgs; [
        cmake
      ];

      # mkdir build && cd build
      environment.make.targets.configure = ''
        rm -rfv clang-config
        mkdir clang-config
        {
          echo "--gcc-install-dir=${gccInstall}"
          echo "-isystem ${pkgs.glibc.dev}/include"
        } > "clang-config/${triplet}.cfg"

        llvm_source="$(dirname "$DIRENV_FILE")"
        cmake \
          "-DCMAKE_INSTALL_PREFIX=$PWD" \
          "-DCLANG_CONFIG_FILE_SYSTEM_DIR=$PWD/clang-config" \
          "-DLLVM_ENABLE_PROJECTS=$1" \
          "-DLLVM_ENABLE_RUNTIMES=libcxx;libcxxabi;libunwind" \
          -DCMAKE_BUILD_TYPE=Debug \
          -G "Unix Makefiles" \
          "$llvm_source/llvm"
      '';
    };
}
