{ hostName, ... }:

{
  imports = [ ./nixpkgs.nix ];

  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    inherit ((import ../../flake.nix).nixConfig) substituters;
  };
  nix.extraOptions = ''
    keep-outputs = true
    keep-derivations = true
  '';

  # https://nixos.wiki/wiki/Storage_optimization
  nix.optimise.automatic = true;
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 29d";
    randomizedDelaySec = "3h";
  };

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

  # To catch some faults:
  systemd.coredump.extraConfig = "Storage=journal";

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
