{
  config,
  lib,
  pkgs,
  n9,
  ...
}:

let
  usercfg = n9.users "boxes" (v: v.n9.virtualisation.boxes) config;
in
{
  # The config MUST be known at evaluate time, thus it can't be generate via
  # functions or other ways, still, infinite recursion.
  config = lib.mkMerge [
    (n9.mkIfUsers (v: v.enable) usercfg {
      # https://nixos.wiki/wiki/Libvirt
      virtualisation.libvirtd =
        let
          ovmf = {
            enable = true;
            packages = [
              (pkgs.OVMF.override {
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
    })

    { users.users = lib.mapAttrs (_: v: lib.mkIf v.enable { extraGroups = [ "libvirtd" ]; }) usercfg; }
  ];
}
