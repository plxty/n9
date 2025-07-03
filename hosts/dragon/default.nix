{
  # Native (For ISO image, use the nixos-x1e repo to build :)
  n9.system.dragon.imports = [
    ./hardware-configuration.nix
    (
      { inputs, ... }:
      {
        imports = [ inputs.nixos-x1e.nixosModules.x1e ];
        hardware.asus-vivobook-s15.enable = true;
        boot.initrd.kernelModules = [
          "dm_mod" # https://github.com/NixOS/nixpkgs/blob/9b5ac7ad45298d58640540d0323ca217f32a6762/nixos/modules/system/boot/kernel.nix#L343
          "i2c_qcom_geni" # MUST load it first before other i2c
          "i2c_hid_of" # Enable keyboard debug early
        ];
      }
    )
    {
      # The xelite machine MUST keep some OEM partitions, therefore don't run
      # disko, and instead part and format the disk yourself, and rename the
      # partition label to:
      # - nvme0n1p12: disk-first-ESP (can reuse the Windows EFI for dual-boot)
      # - nvme0n1p15: disk-first-swap (48G for suspend to disk + real swap)
      # - nvme0n1p16: disk-first-root (three btrfs subvol /mnt/@root /mnt/@home /mnt/@nix)
      #
      # Make btrfs subvolumes:
      # sudo mount /dev/nvme0n1p16 /mnt
      # sudo btrfs subvolume create /mnt/@root /mnt/@home /mnt/@nix
      # sudo umount /mnt
      #
      # And the mountpoint as:
      # sudo mount -o subvol=@root,compress=zstd /dev/nvme0n1p16 /mnt
      # sudo mkdir -p /mnt/{efi,home,nix}
      # sudo mount /dev/nvme0n1p12 /mnt/efi
      # sudo mount -o subvol=@home,compress=zstd /dev/nvme0n1p16 /mnt/home
      # sudo mount -o subvol=@nix,compress=zstd,noatime /dev/nvme0n1p16 /mnt/nix
      #
      # To manually install a system:
      # sudo nixos-install --flake ".#dragon" --root /mnt --no-root-password
      # sudo mkdir -p -m 600 /mnt/etc/nixos/keys/byte
      # mkpasswd | sudo tee /mnt/etc/nixos/keys/byte/passwd
      # sudo chmod 400 /mnt/etc/nixos/keys/byte/passwd
      # sudo reboot
      n9.hardware.disk.nvme0n1.type = "btrfs";

      # Re-use the subscribe from iris:
      n9.network.clash = {
        enable = true;
        subscribe = "../iris/subscribe";
      };

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
          programs.fish.functions = {
            proxy = ''
              if test "$(dconf read /system/proxy/mode)" = "manual"
                dconf write /system/proxy/mode "none"
                echo "proxy off"
              else
                dconf write /system/proxy/http/host "127.0.0.1"
                dconf write /system/proxy/http/port 7890
                dconf write /system/proxy/https/host "127.0.0.1"
                dconf write /system/proxy/https/port 7890
                dconf write /system/proxy/mode "manual"
                echo "proxy on"
              end
            '';

            windows = ''
              sudo bootctl set-oneshot auto-windows
              echo "will boot Windows on next reboot (oneshot)"
            '';
          };

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
