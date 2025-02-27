{
  config,
  lib,
  n9,
  ...
}:

# assert lib.assertMsg (n9 ? userName) "use in users modules!";

let
  cfg = config.n9.security.passwd;
  inherit (n9) userName;
  passwd = "/run/keys/passwd-${userName}";
in
{
  options.n9.security.passwd = {
    file = lib.mkOption {
      type = lib.types.str;
    };
  };

  config = {
    # It's root, that's desired:
    n9.security.secrets.${passwd} = cfg.file;
    users.users.${userName}.hashedPasswordFile = passwd;
  };
}
