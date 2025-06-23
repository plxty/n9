{
  n9.os.evil = {
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

        n9.security.ssh-key = {
          private = "id_ed25519"; # n9/asterisk/evil/byte/id_ed25519
          public = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICw9akIf3We4wbAwVfaqr8ANZYHLbtQ5sQGz1W5ZUE8Y byte@evil";
        };
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
