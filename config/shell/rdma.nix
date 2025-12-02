{
  # TODO: Make a generic GCC environment, which satisfy most of the projects?
  n9.shell.rdma =
    { pkgs, ... }:
    {
      environment.packages = with pkgs; [
        python3Packages.cython
        libnl
      ];

      environment.make.targets = {
        "" = "./build.sh";
        "test" = ''build/bin/run_tests.py "$@"'';
        "compile_commands.json" = "ninja -C build -t compdb > compile_commands.json";
      };
    };
}
