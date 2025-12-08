{
  config,
  lib,
  n9,
  ...
}:

{
  options.users = n9.mkAttrsOfSubmoduleOption { } (
    { name, ... }:
    let
      cfg = cfg.security.passwd.file;
    in
    {
      options.security.passwd.file = lib.mkOption {
        type = lib.types.str;
        default = "${name}/passwd";
      };

      # The r only supports 1-level fold, and because passwd and keys are
      # both in the security, the evaluation will get inifinited recursion.
      # config.r.security.keys.${passwd}.source = cfg;
      config.variant.nixos.users.users.${name}.hashedPasswordFile = "/etc/nixos/keys/${name}/passwd";
    }
  );

  config.security.keys = lib.mkIf config.variant.is.nixos (
    lib.concatMapAttrs (n: v: {
      "/etc/nixos/keys/${n}/passwd".source = v.security.passwd.file;
    }) config.users
  );
}
