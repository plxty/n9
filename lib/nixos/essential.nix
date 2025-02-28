{ n9, pkgs, ... }:

{
  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    # TODO: Try merging with flake.nix::nixConfig? If mismatched,
    # substituers in flake.nix but not in nix.settings will be
    # considered as untrusted, making warnings.
    substituters = [
      "https://mirror.sjtu.edu.cn/nix-channels/store"
      "https://mirrors.ustc.edu.cn/nix-channels/store"
      "https://mirrors.sustech.edu.cn/nix-channels/store"
    ];
  };

  # https://nixos.wiki/wiki/Storage_optimization
  nix.optimise.automatic = true;
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 29d";
    randomizedDelaySec = "3h";
  };

  nixpkgs.overlays = [
    (self: super: {
      helix = n9.lib.patch super.helix ../patches/helix-taste.patch;
      openssh = n9.lib.patch super.openssh ../patches/openssh-plainpass.patch;
      ibus-engines = super.ibus-engines // {
        rime = (n9.lib.patch super.ibus-engines.rime ../patches/ibus-rime-temp-ascii.patch).override {
          rimeDataPkgs = [ (pkgs.callPackage ../pkgs/rime-ice.nix { }) ];
        };
      };
      librime = n9.lib.patch super.librime ../patches/librime-temp-ascii.patch;
      ppp = n9.lib.patch super.ppp ../patches/ppp-run-resolv.patch;

      brave = super.brave.override (prev: {
        commandLineArgs = builtins.concatStringsSep " " [
          (prev.commandLineArgs or "")
          "--wayland-text-input-version=3"
          "--sync-url=https://brave-sync.pteno.cn/v2"
        ];
      });
    })
  ];

  nixpkgs.config.allowUnfree = true;

  boot.loader = {
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = true;
  };

  # For default networking, using NixOS's default (dhcpcd).
  networking = {
    inherit (n9) hostName;
    hostId = builtins.substring 63 8 (builtins.hashString "sha512" n9.hostName);
  };

  environment = {
    sessionVariables.NIX_CRATES_INDEX = "sparse+https://mirrors.ustc.edu.cn/crates.io-index/";
  };

  time.timeZone = "Asia/Shanghai";
  i18n.defaultLocale = "zh_CN.UTF-8";

  virtualisation = {
    containers.enable = true;
    podman = {
      enable = true;
      defaultNetwork.settings.dns_enabled = true;
    };
  };

  system.stateVersion = "25.05";
}
