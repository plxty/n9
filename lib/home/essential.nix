{ pkgs, lib, ... }:

{
  imports = [
    ./fish.nix
    ./zellij.nix
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
    nix-tree
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

  home.file.".local/share/nix/trusted-settings.json" =
    let
      # using osConfig.nix.settings.substituters directly will introduce an
      # extra defult cache.nixos.org, we use this way to avoid it... TODO
      # make a osOptions to obtain the raw values?
      inherit ((import ../../flake.nix).nixConfig) substituters;
    in
    {
      text = ''
        {
          "substituters": { "${lib.concatStringsSep " " substituters}": true }
        }
      '';
      force = true;
    };

  home.stateVersion = "25.05";
}
