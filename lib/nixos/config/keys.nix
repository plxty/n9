{
  config,
  lib,
  n9,
  ...
}:

let
  cfg = config.n9.security.keys;
  usercfg = n9.users "keys" (v: v.n9.security.keys) config;
  keys =
    lib.mapAttrsToList (_: lib.id) cfg
    ++ lib.flatten (lib.mapAttrsToList (_: lib.mapAttrsToList (_: lib.id)) usercfg);
in
{
  # only config here, options are declared in lib/generic/config/keys.nix:
  config.deployment.keys = lib.mkMerge (
    lib.map (v: {
      ${builtins.baseNameOf v.target} = {
        inherit (v)
          user
          group
          permissions
          uploadAt
          ;
        keyFile = v.source;
        destDir = builtins.dirOf v.target;
      };
    }) keys
  );
}
