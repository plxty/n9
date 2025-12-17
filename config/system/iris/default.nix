{
  n9.nixos.iris =
    { lib, pkgs, ... }:
    let
      ports = {
        # physical, from left to right
        rj45-0 = "enp1s0";
        rj45-1 = "enp2s0";
        rj45-2 = "enp4s0";
        sfp-0 = "enp5s0f1np1";
        sfp-1 = "enp5s0f0np0";

        # virtual
        vlan = "enp5s0f1.1210";
        lan = "br-lan";
        wan = "pppoe-wan";
      };

      # TODO: Change the gateway to match DHCP...
      gateway = "10.0.0.1";
      miwifi = "10.254.47.113";
      fwMiIot = "0xadead404";
    in
    {
      hardware.configuration = ./hardware-configuration.nix;
      hardware.disk.mmcblk0.type = "btrfs";

      variant.nixos = {
        boot.initrd.availableKernelModules = [ "usbhid" ];

        # NICs:
        systemd.network.netdevs."10-vlan" = {
          netdevConfig = {
            Kind = "vlan";
            Name = ports.vlan;
          };
          vlanConfig.Id = 1210;
        };
        systemd.network.networks = {
          "10-sfp-0" = {
            matchConfig.Name = ports.sfp-0;
            vlan = [ ports.vlan ];
            networkConfig = {
              DHCP = "no";
              LinkLocalAddressing = "no";
              Address = "192.168.0.2/24"; # XE-99S: 192.168.0.1
            };
            linkConfig.RequiredForOnline = "carrier";
          };
          "11-vlan" = {
            matchConfig.Name = ports.vlan;
            networkConfig = {
              DHCP = "no";
              LinkLocalAddressing = "no";
            };
            linkConfig.RequiredForOnline = "carrier";
          };
        };

        # Static DHCP, seems won't work? @see /var/lib/dnsmasq/dnsmasq.leases
        services.dnsmasq.settings.dhcp-host = [
          "${miwifi},MiWiFi-RC06"
          "10.254.195.65,MiWiFi-RD08"
        ];

        # Forward some ports to the "real" wifi to make miiot work...
        # (It may not works, as the miwifi will match the HTTP Host, it can only be
        # override by the reverse proxy, such as Caddy or Nginx.)
        networking.nftables.tables.miiot = {
          family = "inet";
          content = ''
            chain prerouting {
              type nat hook prerouting priority dstnat;
              iifname ${ports.lan} ip daddr ${gateway} tcp dport { 80, 784 } mark set ${fwMiIot}
              meta mark ${fwMiIot} dnat ip to ${miwifi}
            }

            chain postrouting {
              type nat hook postrouting priority srcnat;
              meta mark ${fwMiIot} masquerade
            }
          '';
        };
      };

      # Router:
      networking.pppoe.${ports.wan}.nic = ports.vlan;
      networking.bridge.${ports.lan} = {
        slaves = with ports; [
          rj45-0
          rj45-1
          rj45-2
        ];
        extraConfig.linkConfig.MTUBytes = "9000";
      };
      networking.router = {
        lan.${ports.lan} = {
          address = "${gateway}/8";
          range = {
            from = "10.254.0.1";
            to = "10.254.254.254";
            mask = "255.0.0.0";
          };
          extraConfig.linkConfig.MTUBytes = "9000";
        };
        wan.${ports.wan}.extraConfig.networkConfig = {
          DHCP = lib.mkForce "ipv6";
          DefaultRouteOnDevice = "yes";
          KeepConfiguration = "static";
        };
        clash.enable = true;
      };

      # TODO: Remoting now...
      # system.variant.nix.settings.trusted-public-keys = [
      #   "coffee.y.xas.is:f2SgLhtRkyjc9yjfW39H9hxPh0KHPMmySJjzhd2whlY="
      # ];
      programs.ssh.server.enable = true;

      deployment = {
        targetHost = "10.0.0.1";
        targetUser = "byte";
      };

      users.byte = {
        programs.helix.enable = false;
        environment.packages = with pkgs; [
          bridge-utils
          tcpdump
          # kubeshark
          mstflint
          ethtool
          nftables
          inetutils
          neovim
        ];

        security.ssh-key.agents = [
          "byte@wyvern"
          "byte@dragon"
        ];
      };
    };
}
