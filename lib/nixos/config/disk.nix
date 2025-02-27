{
  config,
  lib,
  n9,
  ...
}:

let
  # Following @see nixpkgs/nixos/modules/module-list.nix:
  cfg = config.n9.hardware.disk;

  mkDisk =
    dev:
    lib.recursiveUpdate {
      disko.devices.disk.first = {
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
    disko.devices.disk.first.content.partitions.root.content = {
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
    disko.devices.disk.first.content.partitions.root.content = {
      type = "zfs";
      pool = "mix";
    };

    disko.devices.zpool.mix = {
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

  options.n9.hardware.disk = lib.mkOption {
    type = lib.types.attrsOf (
      # The attrTag is forced to be filled for every attributes, while in the
      # submodule you can eliminate those attributes that have default value.
      lib.types.attrTag {
        type = lib.mkOption {
          type = lib.types.enum [
            "btrfs"
            "zfs"
          ];
          default = "btrfs";
        };
      }
    );
  };

  config = n9.lib.mkMergeTopLevel [ "boot" "disko" ] (
    (lib.optional (cfg != { }) {
      boot.loader.efi.efiSysMountPoint = "/efi";
    })
    ++ lib.mapAttrsToList (
      # TODO: Multiple disk?
      # We can't use mkIf here... Must ensure the `disko` is existed, otherwise
      # the inifinte recursion will be back!
      dev: v: mkDisk dev (if v.type == "zfs" then mkZfs else mkBtrfs)
    ) cfg
  );
}
