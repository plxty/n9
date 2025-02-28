{
  config,
  lib,
  n9,
  ...
}:

{
  options.n9.security.passwd = {
    file = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
    };
  };

  # TODO: Make mkMergeTopLevel supports nested attribute?
  config.users.users = lib.mkMerge (
    n9.lib.forAllUsers config "n9.security.passwd" false (
      userName: v:
      lib.mkIf (v.file != null) { "${userName}".hashedPasswordFile = "/run/keys/passwd-${userName}"; }
    )
  );

  config.n9.security.secrets = lib.mkMerge (
    n9.lib.forAllUsers config "n9.security.passwd" false (
      userName: v: lib.mkIf (v.file != null) { "/run/keys/passwd-${userName}".source = v.file; }
    )
  );
}
