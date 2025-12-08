{
  n9.nixos.dragon = {
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

    # X Elite:
    variant.nixos.hardware.asus-vivobook-s15.enable = true;

    users.byte = { };
  };
}
