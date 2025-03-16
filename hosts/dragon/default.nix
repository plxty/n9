{
  n9.os.dragon.imports = [
    ({ inputs, ... }: inputs.nixos-wsl.nixosModules.default)
    (
      { lib, ... }:
      {
        # Against lib/nixos/essential.nix:
        boot.loader = {
          systemd-boot.enable = lib.mkForce false;
          efi.canTouchEfiVariables = lib.mkForce false;
        };
      }
    )
    {
      # sudo nix build '.#nixosConfigurations.dragon.config.system.build.tarballBuilder'
      wsl = {
        enable = true;
        defaultUser = "byte";
      };
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
}
