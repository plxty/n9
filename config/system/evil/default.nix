{
  n9.nixos.evil =
    { lib, pkgs, ... }:
    {
      hardware.configuration = ./hardware-configuration.nix;
      hardware.disk."disk/by-id/nvme-eui.002538b231b633a2".type = "zfs";
      programs.ssh.server.enable = true;

      networking = {
        bridge.br-lan = {
          # From left to right:
          slaves = [ "enp87s0" ];
        };

        router = {
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
      };

      variant.nixos = {
        services.iperf3 = {
          enable = true;
          bind = "10.172.42.1";
        };

        # give qemu a cap_net_admin, @see nixpkgs/nixos/modules/programs/iotop.nix
        security.wrappers = lib.genAttrs [ "qemu-system-x86_64" ] (n: {
          owner = "root";
          group = "root";
          capabilities = "cap_net_admin+p";
          source = "${pkgs.qemu_kvm}/bin/${n}";
        });

        # Try cosmic for fresh:
        services.displayManager.cosmic-greeter.enable = true;
        services.desktopManager.cosmic.enable = true;

        # Fonts, TODO: merge with nix-darwin?
        fonts = {
          enableDefaultPackages = true;
          packages = with pkgs; [
            # essential
            adwaita-fonts
            noto-fonts

            # cjk
            noto-fonts-cjk-sans
            noto-fonts-cjk-serif
            sarasa-gothic
            source-han-sans
            source-han-serif
            wqy_microhei
            wqy_zenhei

            # coding
            nerd-fonts.symbols-only
            jetbrains-mono
            source-code-pro
          ];

          # https://zhuanlan.zhihu.com/p/463403799
          fontconfig.defaultFonts = {
            emoji = [ "Noto Color Emoji" ];
            monospace = [
              "Noto Sans Mono CJK SC"
              "Sarasa Mono SC"
              "DejaVu Sans Mono"
            ];
            sansSerif = [
              "Noto Sans CJK SC"
              "Source Han Sans SC"
              "DejaVu Sans"
            ];
            serif = [
              "Noto Serif CJK SC"
              "Source Han Serif SC"
              "DejaVu Serif"
            ];
          };
        };

        # No networkmanager, we're a "router" handles network ourselves :)
        networking.networkmanager.enable = false;
      };

      users.byte = {
        environment.packages = with pkgs; [
          # cli
          git-repo
          pciutils
          bridge-utils
          minicom
          openocd

          # gui
          brave
          art # or darktable?
          rpi-imager
          wechat
          wpsoffice-cn
        ];

        programs.code-server.enable = true;

        security.ssh-key = {
          private = "id_ed25519";
          public = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIF7yxhz7Xm1rz0/3MkEwLKnIIACjVWFc9GLxwcxhtUy9 byte@evil";
          # agents = [ "byte@subsys" ]; # TODO: put to subsys?
        };

        # FIXME: Add modules/graphics/desktop.nix?
        variant.home-manager.services = {
          ssh-agent.enable = lib.mkForce false;
          gnome-keyring.enable = true;
        };
      };
    };
}
