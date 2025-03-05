{
  n9.os.coffee.imports = [
    ./hardware-configuration.nix
    {
      n9.hardware.disk.nvme0n1.type = "btrfs";
      deployment.allowLocalDeployment = true;

      n9.users.byte.imports = [
        {
          n9.security.passwd.file = "coffee/passwd";
          n9.environment.pop-shell.enable = true;

          n9.security.ssh-key = {
            private = "coffee/id_ed25519";
            public = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBESP6hsTtRCTRchPimo4JVKnhP3l7ydhz49R4CBUyU7 byte@coffee";
          };
        }
      ];
    }
  ];
}
