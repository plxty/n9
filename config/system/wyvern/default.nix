{
  n9.nixos.wyvern = {
    hardware.configuration = ./hardware-configuration.nix;

    variant.nixos = {
      # sudo nix build '.#nixosConfigurations.dragonfly.config.system.build.tarballBuilder'
      wsl = {
        enable = true;
        defaultUser = "byte";
      };

      # @see NixOS-WSL/modules/wsl-distro.nix
      # security.sudo.wheelNeedsPassword = true;
    };

    # After username changes, please do follow:
    # https://nix-community.github.io/NixOS-WSL/how-to/change-username.html
    users.byte = {
      security.ssh-key = {
        private = "id_ed25519";
        public = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGPIHDXatt9Zm7qlyYIs5r+58xtZ2gcqtMx17gpYC7KI byte@wyvern";
      };
    };
  };
}
