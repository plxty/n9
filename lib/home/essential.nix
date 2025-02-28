{ pkgs, ... }:

{
  home.packages = with pkgs; [
    ripgrep
    fd
    wget
    age
    p7zip
    jq
    yq
    bat
    cached-nix-shell

    strace
    sysstat
    lm_sensors
    bcc
    bpftrace
    binwalk
  ];

  services.ssh-agent.enable = true;
  programs.ssh = {
    enable = true;
    addKeysToAgent = "9h";
    forwardAgent = true;
  };

  home.stateVersion = "25.05";
}
