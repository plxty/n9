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
  # @see lib/home/config/passwd.nix
  config = lib.mkMerge [
    (lib.mkIf (usercfg != { }) {
      users.users.root.hashedPassword = "!";

      # If set, the activate script will call update-users-groups.pl everytime
      # you boot up the machine, thus it requires a persisted password file.
      # Don't want to be mutable, but there seems no way to force update the
      # password after we changed files...
      users.mutableUsers = false;
    })

    {
      # Never null now:
      users.users = lib.mapAttrs (n: v: {
        hashedPasswordFile = "/etc/nixos/keys/passwd-${n}";
      }) usercfg;

      n9.security.secrets = lib.concatMapAttrs (n: v: {
        "/etc/nixos/keys/passwd-${n}".source = v.file;
      }) usercfg;
    }
  ];
}
