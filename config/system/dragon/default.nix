{
  n9.nixos.dragon =
    { lib, pkgs, ... }:
    {
      hardware.configuration = ./hardware-configuration.nix;
      hardware.disk.nvme0n1 = {
        type = "btrfs";
        encryption = true;

        # 1-11: OEM filled partitions; TODO: record all?
        partitions.ESP._index = 12;
        # 13: Windows Recovery
        # 14: Windows C:\ drive
        # P.S. RECOVERY(15) and MYASUS(16) are deleted :)
        partitions.swap = {
          uuid = "65967779-967c-45c2-9e46-8e8243ba7b5e"; # uuidgen
          _index = 15;
        };
        partitions.root._index = 16;
      };

      variant.nixos = {
        # Snapdragon X Elite:
        hardware.asus-vivobook-s15.enable = true;

        # FIXME: The EC still have problems, and may cause overheat...
        nix.settings = {
          cores = 3;
          max-jobs = 1;
        };

        # Try cosmic for fresh:
        services.displayManager.cosmic-greeter.enable = true;
        services.desktopManager.cosmic.enable = true;

        # Fonts, TODO: merge with nix-darwin?
        fonts.enableDefaultPackages = true;
        fonts.packages = with pkgs; [
          noto-fonts
          noto-fonts-cjk-sans
          noto-fonts-cjk-serif
          wqy_microhei
          wqy_zenhei
          jetbrains-mono
          source-code-pro
        ];
      };

      users.byte = {
        environment.packages = with pkgs; [
          brave
          art # or darktable?
        ];

        # FIXME: Add modules/graphics/desktop.nix?
        variant.home-manager.services = {
          ssh-agent.enable = lib.mkForce false;
          gnome-keyring.enable = true;
        };
      };
    };
}
