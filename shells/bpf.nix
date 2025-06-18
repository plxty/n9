{ pkgs, ... }:

{
  n9.shell.bpf.imports = [
    {
      rust = {
        enable = true;
        static = true;
      };
      clang = {
        enable = true;
        unwrapped = true;
      };

      packages = with pkgs; [
        pkg-config
        python3
        elfutils
        libbpf
      ];
    }
  ];
}
