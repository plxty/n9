{
  n9.os.wa.imports = [
    ./hardware-configuration.nix
    { boot.initrd.availableKernelModules = [ "usbhid" ]; }
    ./networking.nix
    {
      n9.hardware.disk.mmcblk0.type = "btrfs";
      nix.settings.trusted-public-keys = [
        "coffee.y.xas.is:f2SgLhtRkyjc9yjfW39H9hxPh0KHPMmySJjzhd2whlY="
      ];
      deployment = {
        targetHost = "10.0.0.1";
        targetUser = "byte";
      };

      n9.users.byte.imports = [
        (
          { pkgs, ... }:
          {
            home.packages = with pkgs; [
              bridge-utils
              tcpdump
              mstflint
              ethtool
              nftables
              inetutils
            ];
          }
        )
        {
          n9.security.passwd.file = "wa/passwd";
          n9.security.ssh-key.agents = [ "byte@coffee" ];
        }
      ];
    }
  ];
}
