{
  # Native (For ISO image, use the nixos-x1e repo to build :)
  n9.os.dragon.imports = [
    (
      { inputs, ... }:
      {
        imports = [ inputs.nixos-x1e.nixosModules.x1e ];
        hardware.asus-vivobook-s15.enable = true;
      }
    )
    {
      # The xelite machine MUST keep some OEM partitions, therefore don't run
      # disko, and instead part and format the disk yourself, and rename the
      # partition label to:
      # - /efi : disk-first-ESP
      # - swap : disk-first-swap
      # - / : disk-first-root
      n9.hardware.disk.nvme0n1.type = "btrfs";

      n9.users.byte.imports = [
        (
          { pkgs, ... }:
          {
            home.packages = with pkgs; [
              wechat
            ];
          }
        )
        {
          n9.environment.gnome = {
            enable = true;
            swapCtrlCaps = true;
          };
          n9.security.ssh-key = {
            private = "id_ed25519";
            public = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGPIHDXatt9Zm7qlyYIs5r+58xtZ2gcqtMx17gpYC7KI byte@dragon";
          };
        }
      ];
    }
  ];
}
