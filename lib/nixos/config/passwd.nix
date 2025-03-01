{
  config,
  lib,
  n9,
  ...
}:

let
  mkMergeUsers = n9.lib.mkMergeUsers config "n9.security.passwd";
in
{
  options.n9.security.passwd = {
    file = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
    };
  };

  config.users.users = mkMergeUsers (
    userName: v:
    lib.optionalAttrs (v.file != null) {
      ${userName}.hashedPasswordFile = "/run/keys/passwd-${userName}";
    }
  );

  config.n9.security.secrets = mkMergeUsers (
    userName: v:
    lib.optionalAttrs (v.file != null) {
      "/run/keys/passwd-${userName}".source = v.file;
    }
  );
}
