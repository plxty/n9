{
  n9.os.wa.imports = [
    ./networking.nix
    {
      boot.initrd.availableKernelModules = [ "usbhid" ];
      n9.hardware.disk.mmcblk0.type = "btrfs";
      nix.settings.trusted-public-keys = [
        "coffee.y.xas.is:f2SgLhtRkyjc9yjfW39H9hxPh0KHPMmySJjzhd2whlY="
      ];
      deployment = {
        targetHost = "wa.y.xas.is";
        targetUser = "byte";
      };

      n9.users.byte.imports = [
        (
          { pkgs, ... }:
          {
            home.packages = with pkgs; [
              bridge-utils
              tcpdump
              # kubeshark
              mstflint
              ethtool
              nftables
              inetutils
            ];
          }
        )
        { n9.security.ssh-key.agents = [ "byte@coffee" ]; }
      ];
    }
  ];
}
