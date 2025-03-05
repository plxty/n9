{
  n9.os.harm.imports = [
    { system = "aarch64-linux"; }
    ./hardware-configuration.nix
    (
      { pkgs, ... }:
      {
        boot.kernelPackages = pkgs.linuxPackagesFor (pkgs.callPackage ./linux-kernel-wsl2.nix { });

        # https://github.com/nix-community/nixos-anywhere/issues/18#issuecomment-1500952398
        # https://colmena.cli.rs/unstable/examples/multi-arch.html
        # It takes some times if no nix store cache available...
        # Maybe remote build if the target machine has enough performance.
        # boot.binfmt.emulatedSystems = [ "x86_64-linux" ];
      }
    )
    {
      n9.hardware.disk.sda.type = "btrfs";
      deployment.allowLocalDeployment = true;

      n9.users.byte.imports = [
        { n9.security.passwd.file = "harm/passwd"; }
      ];
    }
  ];
}
