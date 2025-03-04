{
  config,
  lib,
  pkgs,
  self,
  ...
}:

let
  usercfg = self.lib.users "boxes" (v: v.n9.virtualisation.boxes) config;
in
{
  options.n9.virtualisation.boxes = {
    enable = lib.mkEnableOption "boxes";
  };

  # The config MUST be known at evaluate time, thus it can't be generate via
  # functions or other ways, still, infinite recursion.
  config = lib.mkMerge [
    (self.lib.mkIfUsers (v: v.enable) usercfg {
      # https://nixos.wiki/wiki/Libvirt
      virtualisation.libvirtd =
        let
          ovmf = {
            enable = true;
            packages = [
              (pkgs.OVMF.override {
                secureBoot = true;
                tpmSupport = true;
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
    })

    {
      users.users = lib.mapAttrs (
        n: v:
        lib.mkIf v.enable {
          extraGroups = [ "libvirtd" ];
        }
      ) usercfg;

      home-manager.users = lib.mapAttrs (
        n: v:
        lib.mkIf v.enable {
          home.packages = [ pkgs.gnome-boxes ];
          home.file.".config/libvirt/qemu.conf".text = ''
            nvram = [ "/run/libvirt/nix-ovmf/AAVMF_CODE.fd:/run/libvirt/nix-ovmf/AAVMF_VARS.fd", "/run/libvirt/nix-ovmf/OVMF_CODE.fd:/run/libvirt/nix-ovmf/OVMF_VARS.fd" ]
          '';
        }
      ) usercfg;
    }
  ];
}
