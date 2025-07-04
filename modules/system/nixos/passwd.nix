{
  config,
  lib,
  n9,
  this,
  ...
}:

let
  usercfg = n9.users "passwd" (v: v.n9.security.passwd) config;
in
{
  options = lib.optionalAttrs (this ? usersModule) {
    n9.security.passwd = {
      file = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = "${config.home.username}/passwd";
      };
    };
  };

  config = lib.optionalAttrs (!(this ? usersModule)) (
    lib.mkMerge [
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
        users.users = lib.mapAttrs (n: _: {
          hashedPasswordFile = "/etc/nixos/keys/${n}/passwd";
        }) usercfg;

        n9.security.keys = lib.concatMapAttrs (n: v: {
          "/etc/nixos/keys/${n}/passwd".source = v.file;
        }) usercfg;
      }
    ]
  );
}
