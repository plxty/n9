{
  config,
  lib,
  pkgs,
  n9,
  this,
  ...
}:

let
  cfg = config.n9.virtualisation.boxes;
  usercfg = n9.users "boxes" (v: v.n9.virtualisation.boxes) config;
in
{
  options = lib.optionalAttrs (this ? usersModule) {
    n9.virtualisation.boxes = {
      enable = lib.mkEnableOption "boxes";
    };
  };

  config =
    if this ? usersModule then
      lib.mkIf cfg.enable {
        # https://nixos.wiki/wiki/Libvirt /var/lib/libvirt/qemu.conf
        home.packages = [ pkgs.gnome-boxes ];
        home.file.".config/libvirt/qemu.conf".text = ''
          nvram = [
            "/run/libvirt/nix-ovmf/AAVMF_CODE.fd:/run/libvirt/nix-ovmf/AAVMF_VARS.fd",
            "/run/libvirt/nix-ovmf/AAVMF_CODE.ms.fd:/run/libvirt/nix-ovmf/AAVMF_VARS.ms.fd",
            "/run/libvirt/nix-ovmf/OVMF_CODE.fd:/run/libvirt/nix-ovmf/OVMF_VARS.fd",
            "/run/libvirt/nix-ovmf/OVMF_CODE.ms.fd:/run/libvirt/nix-ovmf/OVMF_VARS.ms.fd"
          ]
        '';
      }
    else
      n9.mkIfUsers (v: v.enable) usercfg {
        # https://nixos.wiki/wiki/Libvirt
        virtualisation.libvirtd =
          let
            ovmf = {
              enable = true;
              packages = [
                (pkgs.OVMF.override {
                  qemu = pkgs.qemu_kvm;
                  secureBoot = true;
                  tpmSupport = true;
                  msVarsTemplate = true;
                }).fd
              ];
            };
          in
          {
            enable = true;
            qemu = {
              package = pkgs.qemu_kvm;
              runAsRoot = true;
              swtpm.enable = true;
              inherit ovmf;
            };
          };

        users.users = lib.mapAttrs (
          _: v:
          lib.mkIf v.enable {
            extraGroups = [
              "libvirtd"
              "kvm"
            ];
          }
        ) usercfg;
      };
}
