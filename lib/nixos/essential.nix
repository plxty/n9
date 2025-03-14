{ pkgs, hostName, ... }:

{
  imports = [ ../../pkgs/overlay.nix ];

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

  nix.registry = {
    # nix develop n9#qemu
    n9.to = {
      type = "path";
      path = builtins.toString ../..;
    };
  };

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

  # https://github.com/luishfonseca/nixos-config/blob/main/modules/upgrade-diff.nix
  system.activationScripts.diff = {
    supportsDryActivation = true;
    text = ''
      ${pkgs.nvd}/bin/nvd --nix-bin-dir=${pkgs.nix}/bin diff /run/current-system "$systemConfig"
    '';
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
