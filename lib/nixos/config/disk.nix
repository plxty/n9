{
  config,
  lib,
  n9,
  ...
}:

let
  # Following @see nixpkgs/nixos/modules/module-list.nix:
  cfg = config.n9.hardware.disk;
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

  config = lib.mkMerge [
    (lib.mkIf (cfg != { }) {
      boot.loader.efi.efiSysMountPoint = "/efi";
    })

    {
      # TODO: Multiple disk?
      disko.devices.disk = lib.mergeAttrsList (
        lib.mapAttrsToList (
          dev: v:
          {
            first.type = "disk";
            first.device = "/dev/${dev}";
            first.content.type = "gpt";

            first.content.partitions.ESP = {
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

            first.content.partitions.swap = {
              name = "swap";
              priority = 2;
              size = "16G";
              content.type = "swap";
            };

            first.content.partitions.root = {
              name = "root";
              priority = 3;
              size = "100%";
              content =
                if v.type == "btrfs" then
                  {
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
                  }
                else
                  {
                    type = "zfs";
                    pool = "mix";
                  };
            };
          }
          // lib.optionalAttrs (v.type == "zfs") {
            zpool.mix = {
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
          }
        ) cfg
      );
    }
  ];
}
