{
  # WSL2
  n9.system.wyvern.imports = [
    ./hardware-configuration.nix
    (
      { lib, inputs, ... }:
      {
        imports = [ inputs.nixos-wsl.nixosModules.default ];

        # sudo nix build '.#nixosConfigurations.dragonfly.config.system.build.tarballBuilder'
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
