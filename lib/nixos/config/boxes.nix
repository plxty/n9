{
  config,
  lib,
  pkgs,
  n9,
  ...
}:

let
  usercfg = n9.users "boxes" (v: v.n9.virtualisation.boxes) config;

  # To reduce QEMU compile time, for user-mode, use package `qemu-user` may be better.
  qemu_kvm = pkgs.qemu_kvm.overrideAttrs (prev: {
    configureFlags = prev.configureFlags ++ [ "--disable-user" ];
  });
in
{
  # The config MUST be known at evaluate time, thus it can't be generate via
  # functions or other ways, still, infinite recursion.
  config = n9.mkIfUsers (v: v.enable) usercfg {
    # https://nixos.wiki/wiki/Libvirt
    virtualisation.libvirtd =
      let
        ovmf = {
          enable = true;
          packages = [
            (pkgs.OVMF.override {
              qemu = qemu_kvm;
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
          package = qemu_kvm;
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
