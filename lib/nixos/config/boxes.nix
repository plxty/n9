{
  config,
  lib,
  pkgs,
  n9,
  ...
}:

let
  mkMergeUsers = n9.lib.mkMergeUsers config "n9.virtualisation.boxes";

  home-manager.users = mkMergeUsers (
    userName: v:
    lib.optionalAttrs (v.enable) {
      ${userName} = {
        home.packages = [ pkgs.gnome-boxes ];
        home.file.".config/libvirt/qemu.conf".text = ''
          nvram = [ "/run/libvirt/nix-ovmf/AAVMF_CODE.fd:/run/libvirt/nix-ovmf/AAVMF_VARS.fd", "/run/libvirt/nix-ovmf/OVMF_CODE.fd:/run/libvirt/nix-ovmf/OVMF_VARS.fd" ]
        '';
      };
    }
  );
in
{
  options.n9.virtualisation.boxes = {
    enable = lib.mkEnableOption "boxes";
  };

  # The config MUST be known at evaluate time, thus it can't be generate via
  # functions or other ways, still, infinite recursion.
  config = lib.mkMerge [
    (lib.mkIf (home-manager.users != { }) {
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
      users.users = mkMergeUsers (
        userName: v:
        lib.optionalAttrs (v.enable) {
          ${userName}.extraGroups = [ "libvirtd" ];
        }
      );

      inherit home-manager;
    }
  ];
}
