{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.n9.virtualisation.boxes;
in
{
  options.n9.virtualisation.boxes = {
    enable = lib.mkEnableOption "boxes";
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.gnome-boxes ];
    home.file.".config/libvirt/qemu.conf".text = ''
      nvram = [ "/run/libvirt/nix-ovmf/AAVMF_CODE.fd:/run/libvirt/nix-ovmf/AAVMF_VARS.fd", "/run/libvirt/nix-ovmf/OVMF_CODE.fd:/run/libvirt/nix-ovmf/OVMF_VARS.fd" ]
    '';
  };
}
