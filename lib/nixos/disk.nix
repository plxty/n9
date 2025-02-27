{
  config,
  lib,
  n9,
  ...
}:

let
  mkDisk =
    dev:
    lib.recursiveUpdate {
      devices.disk.first = {
        type = "disk";
        device = "/dev/${dev}";

        content = {
          type = "gpt";

          partitions.ESP = {
            name = "ESP";
            priority = 1;
            start = "1M";
            size = "1G";
            type = "EF00";
            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/efi";
              mountOptions = [ "umask=0077" ];
            };
          };

          partitions.swap = {
            name = "swap";
            priority = 2;
            size = "16G";
            content.type = "swap";
          };

          partitions.root = {
            name = "root";
            priority = 3;
            size = "100%";
          };
        };
      };
    };

  mkBtrfs = {
    devices.disk.first.content.partitions.root.content = {
      type = "btrfs";
      extraArgs = [ "-f" ];

      subvolumes."/@root" = {
        mountpoint = "/";
        mountOptions = [ "compress=zstd" ];
      };

      subvolumes."/@home" = {
        mountpoint = "/home";
        mountOptions = [ "compress=zstd" ];
      };

      subvolumes."/@nix" = {
        mountpoint = "/nix";
        mountOptions = [
          "compress=zstd"
          "noatime"
        ];
      };
    };
  };

  mkZfs = {
    devices.disk.first.content.partitions.root.content = {
      type = "zfs";
      pool = "mix";
    };

    devices.zpool.mix = {
      type = "zpool";
      options.ashift = "13";
      rootFsOptions.compression = "zstd";

      datasets.root = {
        type = "zfs_fs";
        mountpoint = "/";
      };

      datasets.home = {
        type = "zfs_fs";
        mountpoint = "/home";
        options.dedup = "on";
      };

      datasets.nix = {
        type = "zfs_fs";
        mountpoint = "/nix";
      };
    };
  };
in
{
  imports = [ n9.inputs.disko.nixosModules.disko ];

  options.hardware.disk = lib.mkOption {
    type = lib.types.attrsOf (
      # The attrTag is forced to be filled for every attributes, while in the
      # submodule you can eliminate those attributes that have default value.
      lib.types.submodule {
        options.enable = lib.mkOption {
          type = lib.types.bool;
          default = true;
        };

        options.type = lib.mkOption {
          type = lib.types.enum [
            "btrfs"
            "zfs"
          ];
          default = "btrfs";
        };
      }
    );
  };

  config = {
    # Think it's better here, with the disk and partitions?
    boot.loader.efi.efiSysMountPoint = "/efi";

    # TODO: Multiple disk?
    disko = lib.mkMerge (
      lib.mapAttrsToList (
        dev: v: lib.mkIf v.enable (mkDisk dev (if v.type == "zfs" then mkZfs else mkBtrfs))
      ) config.hardware.disk
    );
  };
}
