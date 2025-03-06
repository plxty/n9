{
  pkgs,
  self,
  hostName,
  ...
}:

{
  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    inherit ((import ../../flake.nix).nixConfig) substituters;
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
    (_: super: {
      helix = self.lib.patch super.helix ../patches/helix-taste.patch;
      openssh = self.lib.patch super.openssh ../patches/openssh-plainpass.patch;
      ibus-engines = super.ibus-engines // {
        rime = (self.lib.patch super.ibus-engines.rime ../patches/ibus-rime-temp-ascii.patch).override {
          rimeDataPkgs = [ (pkgs.callPackage ../pkgs/rime-ice.nix { }) ];
        };
      };
      librime = self.lib.patch super.librime ../patches/librime-temp-ascii.patch;
      ppp = self.lib.patch super.ppp ../patches/ppp-run-resolv.patch;

      brave = super.brave.override (prev: {
        commandLineArgs = builtins.concatStringsSep " " [
          (prev.commandLineArgs or "")
          "--wayland-text-input-version=3"
          "--sync-url=https://brave-sync.pteno.cn/v2"
        ];
      });

      linux_wsl2 = pkgs.linuxPackagesFor (pkgs.callPackage ../pkgs/linux-kernel-wsl2.nix);
    })
  ];

  nixpkgs.config.allowUnfree = true;

  boot.loader = {
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = true;
  };

  # For default networking, using NixOS's default (dhcpcd).
  networking = {
    inherit hostName;
    hostId = builtins.substring 63 8 (builtins.hashString "sha512" hostName);
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
