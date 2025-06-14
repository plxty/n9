{ osConfig, pkgs, ... }:

{
  services.ssh-agent.enable = true;
  home.packages = with pkgs; [
    strace
    sysstat
    lm_sensors
    bpftrace
    osConfig.boot.kernelPackages.perf
    smartmontools
  ];
}
