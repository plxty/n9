{
  # We're using GCC to compile, correct?
  n9.shell.llvm =
    { pkgs, ... }:
    {
      # TODO: Make environment.packages points to here:
      variant.shell.depsBuildBuild = with pkgs; [
        cmake
      ];

      # mkdir build && cd build
      environment.make.targets.configure = ''
        llvm_source="$(dirname "$DIRENV_FILE")"
        cmake \
          "-DLLVM_ENABLE_PROJECTS=$1" \
          -DCMAKE_BUILD_TYPE=Debug \
          -G "Unix Makefiles" \
          "$llvm_source/llvm"
      '';
    };
}
