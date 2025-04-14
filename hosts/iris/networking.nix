# 10.0.0.1 => Router
# 10.254.0.0 => DHCP
# 10.29.0.0 => PXE (later)
# 10.42.0.0 => Proxy
# May conflicts with?

{ pkgs, n9, ... }:

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
    wan = "pppoe-wan";
    lan = "br-lan";
  };

  gateway = "10.0.0.1";
  miwifi = "10.254.47.113";

  mkJumboLanBridgeSlave =
    port: master:
    n9.mkCarrierOnlyNetwork port {
      networkConfig.Bridge = master;
      linkConfig = {
        MTUBytes = "9000";
        RequiredForOnline = "enslaved";
      };
    };
in
{
  n9.network.router = {
    lan.${ports.lan} = {
      address = "${gateway}/8";
      range = {
        from = "10.254.0.1";
        to = "10.254.254.254";
        mask = "255.0.0.0"; # should be the same as address
      };
      extraConfig.linkConfig.MTUBytes = "9000";
    };

    wan.${ports.wan}.enable = true;
  };

  # Netdev:
  systemd.network.netdevs = {
    "10-vlan" = {
      netdevConfig = {
        Kind = "vlan";
        Name = ports.vlan;
      };
      vlanConfig.Id = 1210;
    };

    "20-lan" = {
      netdevConfig = {
        Kind = "bridge";
        Name = ports.lan;
      };
    };
  };

  # PPPoE (netdev), networkd managed as well:
  networking.useDHCP = false;
  networking.dhcpcd.enable = false;
  boot.kernelModules = [ "pppoe" ];

  n9.security.keys."/etc/ppp/keys/wan".source = "wan";
  services.pppd = {
    enable = true;
    # https://man7.org/linux/man-pages/man8/pppd.8.html
    peers.wan.config = ''
      plugin pppoe.so
      ifname ${ports.wan}
      nic-${ports.vlan}
      file /etc/ppp/keys/wan

      persist
      maxfail 0
      holdoff 10

      +ipv6 ipv6cp-use-ipaddr
      defaultroute
      usepeerdns
      noipdefault
    '';
  };

  # Networks:
  systemd.network.networks = {
    "10-sfp-0" = n9.mkCarrierOnlyNetwork ports.sfp-0 {
      vlan = [ ports.vlan ];
      networkConfig.Address = "192.168.0.2/24"; # XE-99S: 192.168.0.1
    };
    "11-vlan" = n9.mkCarrierOnlyNetwork ports.vlan { };

    "20-rj45-0" = mkJumboLanBridgeSlave ports.rj45-0 ports.lan;
    "21-rj45-1" = mkJumboLanBridgeSlave ports.rj45-1 ports.lan;
    "22-rj45-2" = mkJumboLanBridgeSlave ports.rj45-2 ports.lan;
    "23-wan" = n9.mkCarrierOnlyNetwork ports.wan {
      # https://wiki.debian.org/IPv6PrefixDelegation
      networkConfig = {
        DHCP = "ipv6";
        DefaultRouteOnDevice = "yes";
        KeepConfiguration = "static";
        LinkLocalAddressing = "ipv6";
      };
      dhcpV6Config = {
        PrefixDelegationHint = "::/64";
        WithoutRA = "solicit";
        UseDNS = "no";
        UseHostname = "no";
      };
      linkConfig.RequiredForOnline = "yes"; # TODO: Is it really working?
    };
  };

  # Relavents:
  services.networkd-dispatcher = {
    enable = true;
    rules."restart-dnsmasq" = {
      onState = [ "routable" ];
      script = ''
        #!${pkgs.runtimeShell}
        if [[ "$IFACE" == "${ports.wan}" && "$AdministrativeState" == "configured" ]]; then
          systemctl restart dnsmasq
        fi
        exit 0
      '';
    };
  };

  # DNS and TFTP, and more:
  services.dnsmasq.settings = {
    interface = [ "lo" ];

    resolv-file = "/run/pppd/resolv.conf";
    server = [
      "223.5.5.5"
      "119.29.29.29"
    ];

    # @see /var/lib/dnsmasq/dnsmasq.leases
    dhcp-host = [
      "${miwifi},MiWiFi-RC06"
    ];

    # tftp, TODO: https://nixos.wiki/wiki/Netboot
    enable-tftp = true;
    tftp-root = "/srv/tftp";
  };

  systemd.tmpfiles.rules = [ "d /srv/tftp 0777 dnsmasq dnsmasq -" ];

  # Forward some ports to the "real" wifi to make miiot work...
  # (It may not works, as the miwifi will match the HTTP Host, it can only be
  # override by the reverse proxy, such as Caddy or Nginx.)
  networking.nftables.tables.miiot = {
    family = "inet";
    content = ''
      chain prerouting {
        type nat hook prerouting priority dstnat;
        iifname ${ports.lan} ip daddr ${gateway} tcp dport { 80, 784 } mark set 404
        meta mark 404 dnat ip to ${miwifi}
      }

      chain postrouting {
        type nat hook postrouting priority srcnat;
        meta mark 404 masquerade
      }
    '';
  };
}
