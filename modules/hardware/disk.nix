{
  config,
  lib,
  n9,
  ...
}:

# To run, TODO: shorthands in colmenaHive?
# nix build ".#colmenaHive.nodes.$(hostname).config.variant.nixos.system.build.diskoScript"
# sudo bash ./result

let
  cfg = config.hardware.disk;
in
{
  options.hardware.disk = n9.mkAttrsOfSubmoduleOption { default = { }; } {
    options.name = lib.mkOption {
      type = lib.types.str;
      default = "first"; # backward compat
    };

    options.type = lib.mkOption {
      type = lib.types.enum [
        "btrfs"
        "zfs"
      ];
    };

    # Is extra disks, i.e. not system bootable:
    # TODO: Assertion for only one main disk?
    options.extra = lib.mkEnableOption "extra";

    # TODO: Won't work for zfs currently...
    options.encryption = lib.mkEnableOption "encryption";

    # Partitions follow disko, TODO: options alias?
    options.partitions = lib.mkOption {
      type = lib.types.attrsOf lib.types.attrs;
      default = { };
    };

    # zfs-only, TODO: using just ${name}? Here to keep old things work:
    options.pool = lib.mkOption {
      type = lib.types.str;
      default = "mix";
    };
  };

  # If there's no (bootable) disk, e.g. WSL2, then boot loader is meaningless.
  # TODO: Move out:
  config.variant.nixos.boot = lib.mkIf (cfg != { }) {
    loader = {
      systemd-boot.enable = true;
      systemd-boot.edk2-uefi-shell.enable = true; # for debugging...
      efi.canTouchEfiVariables = true;
      efi.efiSysMountPoint = "/efi";
    };
    initrd.systemd.enable = true;
  };

  config.variant.nixos.disko.devices.disk = lib.concatMapAttrs (dev: v: {
    ${v.name} = {
      type = "disk";
      device = "/dev/${dev}";
      content.type = "gpt";

      # Should destroy by hand, to ensure the safety, and to double check:
      # For new machine, just remove all partitions, and it should works.
      destroy = false;

      content.partitions = lib.mkMerge [
        (lib.mkIf (!v.extra) {
          ESP = {
            name = "ESP";
            start = "1M";
            size = lib.mkDefault "1G";
            type = "EF00";
            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/efi";
              mountOptions = [ "umask=0077" ];
            };
          };
          swap = {
            name = "swap";
            size = "16G";
            # Note: MUST define the "uuid" to use the partuuid, the NixOS will
            # erase all partlabel at boot, @see swapDevices.*.randomEncryption
            uuid = lib.mkIf v.encryption (
              lib.mkDefault (lib.throwIf true "Please define uuid for the encrypted swap!" (_: null))
            );
            content = {
              type = "swap";
              discardPolicy = "both";
              # TODO: It doesn't support suspend currently...
              randomEncryption = v.encryption;
            };
          };
          root =
            let
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
                    inherit (v) pool;
                  };
            in
            {
              name = lib.mkIf (!v.encryption) "root";
              size = "100%";
              content =
                if v.encryption then
                  {
                    type = "luks";
                    name = "root";
                    settings.allowDiscards = true;
                    inherit content;
                  }
                else
                  content;
            };
        })

        # custom partitions here:
        v.partitions
      ];
    };
  }) cfg;

  # To reduce indents...
  config.variant.nixos.disko.devices.zpool = lib.concatMapAttrs (
    dev: v:
    lib.optionalAttrs (v.type == "zfs" && !v.extra) {
      ${v.pool} = {
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
        };
        datasets.nix = {
          type = "zfs_fs";
          mountpoint = "/nix";
        };
      };
    }
  ) cfg;
}
