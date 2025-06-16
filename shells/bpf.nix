{
  n9.shell."bpf.arm64".imports = [
    (
      { pkgs, pkgsCross, ... }:
      {
        triplet = "aarch64-unknown-linux-gnu";
        rust.enable = true;
        clang = {
          enable = true;
          unwrapped = true;
        };

        depsBuildBuild = with pkgs; [
          # pkgsCross.buildPackages.pkg-config # should it?
          pkg-config
        ];

        packages = with pkgsCross; [
          elfutils
          libbpf
        ];
      }
    )
  ];
}
