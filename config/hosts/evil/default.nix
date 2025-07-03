{
  n9.system.evil = {
    imports = [ ./hardware-configuration.nix ];

    n9.hardware.disk."disk/by-id/nvme-eui.002538b231b633a2".type = "zfs";
    n9.services.sshd.enable = true;
    deployment.allowLocalDeployment = true;

    n9.users.byte.imports = [
      (
        { pkgs, ... }:
        {
          home.packages = with pkgs; [
            git-repo
            jetbrains.clion
            zenity
            freerdp3
            rpi-imager
            minicom
            openocd
          ];
        }
      )
      {
        n9.environment.gnome.enable = true;
        n9.virtualisation.boxes.enable = true;
      }
    ];

    # To access to dev boards:
    n9.network.router = {
      lan.enp91s0 = {
        address = "10.0.0.1/8";
        range = {
          from = "10.254.254.0";
          to = "10.254.254.254";
          mask = "255.255.255.0";
        };
      };
      wan.enp92s0.enable = true;
    };
    services.dnsmasq.settings.dhcp-host = [
      "2c:cf:67:d7:25:bc,10.254.254.33,pi"
    ];
    users.users.byte.extraGroups = [ "dialout" ];
  };
}
