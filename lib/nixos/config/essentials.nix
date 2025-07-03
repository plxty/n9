{
  config,
  pkgs,
  lib,
  hostName,
  ...
}:

let
  cfg = config.n9.essentials.nixos;
in
{
  options.n9.essentials.nixos.enable = lib.mkOption {
    type = lib.types.bool;
    default = true;
  };

  config = lib.mkIf cfg.enable {
    boot.loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };

    # For default networking, using NixOS's default (dhcpcd).
    networking = {
      inherit hostName;
      hostId = builtins.substring 63 8 (builtins.hashString "sha512" hostName);
    };

    environment.sessionVariables = {
      NIX_CRATES_INDEX = "sparse+https://mirrors.ustc.edu.cn/crates.io-index/";
      REPO_URL = "https://mirrors.tuna.tsinghua.edu.cn/git/git-repo";
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

    # To run "native" linux elf, such as vscode remote server:
    programs.nix-ld = {
      enable = true;
      package = pkgs.nix-ld-rs;
    };

    # nixos-only
    nix.gc = {
      dates = "weekly";
      randomizedDelaySec = "3h";
    };

    # TODO: The standalone home doesn't support it:
    nix.optimise.automatic = true;

    system.stateVersion = "25.05";
  };
}
