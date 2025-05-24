{
  # WSL2
  n9.os.dragonfly.imports = [
    (
      { lib, inputs, ... }:
      {
        imports = [ inputs.nixos-wsl.nixosModules.default ];

        # sudo nix build '.#nixosConfigurations.dragon.config.system.build.tarballBuilder'
        wsl = {
          enable = true;
          defaultUser = "byte";
        };

        # @see NixOS-WSL/modules/wsl-distro.nix
        security.sudo.wheelNeedsPassword = true;

        # Against lib/nixos/essential.nix:
        boot.loader.systemd-boot.enable = lib.mkForce false;
      }
    )
    {
      deployment.allowLocalDeployment = true;

      # After username changes, please do follow:
      # https://nix-community.github.io/NixOS-WSL/how-to/change-username.html
      n9.users.byte.imports = [
        {
          n9.security.ssh-key = {
            private = "id_ed25519";
            public = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGPIHDXatt9Zm7qlyYIs5r+58xtZ2gcqtMx17gpYC7KI byte@dragon";
          };
        }
      ];
    }
  ];

  # Native (ISO use the x1e-nixos repo :)
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
      deployment.allowLocalDeployment = true;

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
