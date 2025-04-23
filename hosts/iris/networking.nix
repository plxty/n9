{
  pkgs,
  n9,
  lib,
  ...
}:

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
  fwClash = "0xfeedc1a5";

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
        mask = "255.0.0.0";
      };
      extraConfig.linkConfig.MTUBytes = "9000";
    };

    wan.${ports.wan}.enable = true;
  };

  boot.kernelModules = [
    "pppoe"
    "nft_socket"
    "nft_tproxy"
  ];

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

  n9.security.keys."/etc/ppp/keys/wan".source = "wan";
  services.pppd = {
    enable = true;
    package = n9.patch pkgs.ppp "ppp-run-resolv";
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

    # The policy route is mandatory, because tproxy won't stop nf hooks and it
    # won't change the packet, the `ip_forward` can hard to tell where to route
    # the packet, we need to tell it routing to lo device, and there's mihomo.
    "30-clash" = n9.mkCarrierOnlyNetwork "lo" {
      routes = [
        {
          Table = 100; # any of it, 42, 101, ...
          Destination = "0.0.0.0/0";
          Type = "local";
        }
      ];
      routingPolicyRules = [
        {
          FirewallMark = fwClash;
          Table = 100;
          Priority = 100;
        }
      ];
    };
  };

  # Relavents:
  services.networkd-dispatcher = {
    enable = true;
    rules."restart-resolve" = {
      onState = [ "routable" ];
      script = ''
        #!${pkgs.runtimeShell}
        if [[ "$IFACE" == "${ports.wan}" && "$AdministrativeState" == "configured" ]]; then
          systemctl restart dnsmasq mihomo
        fi
        exit 0
      '';
    };
  };

  # DNS and TFTP, and more:
  services.dnsmasq.settings = {
    interface = [ "lo" ];

    strict-order = true;
    resolv-file = "/run/pppd/resolv.conf";
    server = [
      "127.0.0.1#1053"
      "223.5.5.5"
      "119.29.29.29"
    ];

    # @see /var/lib/dnsmasq/dnsmasq.leases
    dhcp-host = [
      "${miwifi},MiWiFi-RC06"
      "10.254.195.65,MiWiFi-RD08"
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
        iifname ${ports.lan} ip daddr ${gateway} tcp dport { 80, 784 } mark set ${fwMiIot}
        meta mark ${fwMiIot} dnat ip to ${miwifi}
      }

      chain postrouting {
        type nat hook postrouting priority srcnat;
        meta mark ${fwMiIot} masquerade
      }
    '';
  };

  # Old new world:
  services.mihomo = {
    enable = true;
    package = n9.patch pkgs.mihomo "mihomo-taste";
    configFile = "/etc/mihomo/clash.yaml";
    webui = pkgs.metacubexd;
    tunMode = true; # tproxy needs it as well
  };

  # https://github.com/NixOS/nixpkgs/blob/26d499fc9f1d567283d5d56fcf367edd815dba1d/nixos/modules/system/boot/systemd.nix#L747C1-L748C1
  systemd.services.clash-renew = {
    requires = [ "network-online.target" ];
    after = [ "network-online.target" ];
    path = with pkgs; [
      (python3.withPackages (py3: [ py3.pyyaml ]))
      curl
    ];
    serviceConfig =
      let
        dir = lib.fileset.toSource {
          root = ./.;
          fileset = ./clash-renew.py;
        };
      in
      {
        Type = "oneshot";
        ExecStart = "${dir}/clash-renew.py";
      };
  };
  n9.security.keys."/etc/mihomo/subscribe".source = "subscribe";

  # Make mihomo depends:
  systemd.services.mihomo = {
    requires = [ "clash-renew.service" ];
    after = [ "clash-renew.service" ];
    startAt = "Mon,Tue,Thu,Sat *-*-* 05:06:07";
  };

  # https://github.com/Seidko/my-linux-note/blob/master/tproxy%20with%20clash%20and%20nftables.md
  # TODO: Redirect GeoIP to clash? TUN? Restrict to lan port only?
  # Trace packet with `meta nftrace set 1`, monitor with shell `nft monitor trace`.
  networking.nftables.tables.clash = {
    family = "inet";
    content = ''
      chain prerouting {
        type filter hook prerouting priority mangle;
        ip daddr 198.18.0.0/15 meta l4proto { tcp, udp } mark set ${fwClash} \
          tproxy ip to 127.0.0.1:7892 counter
      }
    '';
  };

  networking.firewall = {
    # To forward tproxy traffic to lo, nf doesn't support something like always-accept.
    extraReversePathFilterRules = "meta mark ${fwClash} accept";
    extraInputRules = "meta mark ${fwClash} accept";
    interfaces.${ports.lan}.allowedTCPPorts = [
      7890 # http:// proxy
      9090 # metacubexd, access /ui
    ];
  };
}
