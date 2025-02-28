{
  config,
  lib,
  pkgs,
  n9,
  ...
}:

let
  cfg = n9.lib.forAllUsers config "n9.virtualisation.boxes" false;

  enable = lib.any lib.id (cfg (_: v: v.enable or false));
in
{
  options.n9.virtualisation.boxes = {
    enable = lib.mkEnableOption "boxes";
  };

  # The config MUST be known at evaluate time, thus it can't be generate via
  # functions or other ways, still, infinite recursion.
  config = lib.mkMerge [
    (lib.mkIf enable {
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
      # TODO: Simplify?
      users.users = lib.mergeAttrsList (
        cfg (
          userName: v:
          lib.optionalAttrs (v.enable or false) {
            "${userName}".extraGroups = [ "libvirtd" ];
          }
        )
      );

      home-manager.users = lib.mergeAttrsList (
        cfg (
          userName: v:
          lib.optionalAttrs (v.enable or false) {
            "${userName}" = {
              home.packages = [ pkgs.gnome-boxes ];
              home.file.".config/libvirt/qemu.conf".text = ''
                nvram = [ "/run/libvirt/nix-ovmf/AAVMF_CODE.fd:/run/libvirt/nix-ovmf/AAVMF_VARS.fd", "/run/libvirt/nix-ovmf/OVMF_CODE.fd:/run/libvirt/nix-ovmf/OVMF_VARS.fd" ]
              '';
            };
          }
        )
      );
    }
  ];
}
