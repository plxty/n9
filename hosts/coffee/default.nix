{
  n9.os.coffee.imports = [
    {
      n9.hardware.disk.nvme0n1.type = "btrfs";
      deployment.allowLocalDeployment = true;

      n9.users.byte.imports = [
        (
          { pkgs, ... }:
          {
            home.packages = [ pkgs.wechat ];
          }
        )
        {
          n9.environment.gnome.enable = true;
          n9.security.ssh-key = {
            private = "id_ed25519";
            public = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBESP6hsTtRCTRchPimo4JVKnhP3l7ydhz49R4CBUyU7 byte@coffee";
          };
        }
      ];
    }
  ];
}
