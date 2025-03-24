{
  osConfig,
  pkgs,
  lib,
  ...
}:

{
  imports = [
    ./fish.nix
    ./helix.nix
  ];

  home.packages = with pkgs; [
    wget
    p7zip
    unrar
    jq
    yq
    python3
    cached-nix-shell
    pstree
    binutils
    file
    strace
    sysstat
    lm_sensors
    bcc
    bpftrace
    binwalk
    smartmontools
  ];

  services.ssh-agent.enable = true;
  programs.ssh = {
    enable = true;
    addKeysToAgent = "9h";
    forwardAgent = true;
  };

  programs.git = {
    enable = true;
    userName = "Zigit Zo";
    userEmail = "repl@z.xas.is";
    signing.format = "ssh";
    extraConfig = {
      user.useConfigOnly = true;
      init.defaultBranch = "main";
    };
  };

  home.file.".config/nixpkgs/config.nix".text = ''
    { allowUnfree = true; }
  '';

  home.file.".local/share/nix/trusted-settings.json" = {
    text = ''
      {
        "substituters": { "${lib.concatStringsSep " " osConfig.nix.settings.substituters}": true },
      }
    '';
    force = true;
  };

  home.stateVersion = "25.05";
}
