{
  inputs.n9.url = "../../irix";

  outputs =
    { self, n9, ... }:
    {
      nixosConfigurations = n9.lib.nixos self {
        system = "aarch64-linux";
        modules = with n9.lib.nixos-modules; [
          ./hardware-configuration.nix
          (
            { pkgs, ... }:
            {
              boot.kernelPackages = pkgs.linuxPackagesFor (pkgs.callPackage ./linux-kernel-wsl2.nix { });
            }
          )
          (disk.btrfs "/dev/sda")
        ];
      };

      homeConfigurations = n9.lib.home (n9.lib.utils.user2 "byte" ./passwd) {
        modules = with n9.lib.home-modules; [
          editor.helix
          shell.fish
          (secret.ssh-key ./id_ed25519 "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILb5cEj9hvj32QeXnCD5za0VLz56yBP3CiA7Kgr1tV5S byte@harm")
        ];
      };
    };
}
