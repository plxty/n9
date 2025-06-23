{ pkgs, ... }:

{
  n9.shell.bpfd = {
    packages = with pkgs; [
      go
    ];
  };
}
