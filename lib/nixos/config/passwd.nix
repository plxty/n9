{
  config,
  lib,
  self,
  ...
}:

let
  usercfg = self.lib.users "passwd" (v: v.n9.security.passwd) config;
in
{
  options.n9.security.passwd = {
    file = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
    };
  };

  config = lib.mkMerge [
    {
      users.users = lib.mapAttrs (
        n: v:
        lib.mkIf (v.file != null) {
          hashedPasswordFile = "/run/keys/passwd-${n}";
        }
      ) usercfg;

      n9.security.secrets = lib.concatMapAttrs (
        n: v:
        lib.mkIf (v.file != null) {
          "/run/keys/passwd-${n}".source = v.file;
        }
      ) usercfg;
    }
  ];
}
