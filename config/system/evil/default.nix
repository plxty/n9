{
  n9.nixos.evil =
    { lib, pkgs, ... }:
    {
      hardware.configuration = ./hardware-configuration.nix;
      hardware.disk."disk/by-id/nvme-eui.002538b231b633a2".type = "zfs";
      programs.ssh.server.enable = true;

      variant.nixos.services.iperf3 = {
        enable = true;
        bind = "10.172.42.1";
      };

      networking.bridge.br-lan = {
        # From left to right:
        slaves = [ "enp87s0" ];
      };
      networking.router = {
        lan.br-lan = {
          address = "10.172.42.1/24";
          range = {
            from = "10.172.42.100";
            to = "10.172.42.254";
            mask = "255.255.255.0";
          };
        };
        wan.enp88s0 = { };
        clash.enable = true;
      };

      # give qemu a cap_net_admin, @see nixpkgs/nixos/modules/programs/iotop.nix
      variant.nixos.security.wrappers = lib.genAttrs [ "qemu-system-x86_64" ] (n: {
        owner = "root";
        group = "root";
        capabilities = "cap_net_admin+p";
        source = "${pkgs.qemu_kvm}/bin/${n}";
      });

      users.byte = {
        environment.packages = with pkgs; [
          git-repo
          pciutils
          bridge-utils
          rpi-imager
          minicom
          openocd
        ];

        programs.code-server.enable = true;

        security.ssh-key = {
          private = "id_ed25519";
          public = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIF7yxhz7Xm1rz0/3MkEwLKnIIACjVWFc9GLxwcxhtUy9 byte@evil";
          agents = [
            "byte@wyvern"
            # "byte@subsys"
          ];
        };
      };
    };
}
