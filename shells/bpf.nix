{ pkgs, ... }:

{
  n9.shell.bpf.imports = [
    (
      { pkgsCross, ... }:
      {
        rust = {
          enable = true;
          static = true;
        };
        clang = {
          enable = true;
          unwrapped = true;
        };

        depsBuildBuild = with pkgs; [
          pkg-config
          python3
        ];

        packages = with pkgsCross; [
          elfutils
          libbpf
        ];
      }
    )
  ];
}
