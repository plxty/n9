{
  n9.os.wa.imports = [
    ./hardware-configuration.nix
    ./networking.nix
    {
      n9.hardware.disk.mmcblk0.type = "btrfs";
      # nix.settings.trusted-public-keys = [ "..." ];
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
