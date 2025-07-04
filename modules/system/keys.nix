{
  config,
  osConfig,
  lib,
  n9,
  this,
  ...
}:

let
  cfg = config.n9.security.keys;
  usercfg = n9.users "keys" (v: v.n9.security.keys) config;
  keys =
    lib.mapAttrsToList (_: lib.id) cfg
    ++ lib.flatten (lib.mapAttrsToList (_: lib.mapAttrsToList (_: lib.id)) usercfg);

  hostName = osConfig.networking.hostName;
  userName = config.home.username;
in
{
  options.n9.security.keys = lib.mkOption {
    type = lib.types.attrsOf (
      # @see home-manager/modules/lib/file-type.nix
      # @see https://colmena.cli.rs/unstable/reference/deployment.html
      lib.types.submodule (
        { name, ... }:
        {
          options = {
            source = lib.mkOption {
              type = lib.types.str;
              apply =
                k:
                let
                  basedir = "${n9.dir}/asterisk/${hostName}";
                in
                assert lib.assertMsg (lib.hasPrefix "/" basedir) "wrong secret directory!";
                if this ? usersModule then "${basedir}/${userName}/${k}" else "${basedir}/${k}";
            };

            target = lib.mkOption {
              type = lib.types.str;
              default = name;
              apply = v: if this ? usersModule then "${config.home.homeDirectory}/${v}" else v;
            };

            user = lib.mkOption {
              type = lib.types.str;
              default = if this ? usersModule then userName else "root";
            };

            group = lib.mkOption {
              type = lib.types.str;
              default =
                if this ? usersModule then
                  userName
                else if this ? nixos then
                  "root"
                else if this ? darwin then
                  "staff"
                else
                  abort "unsupported user group!";
            };

            permissions = lib.mkOption {
              type = lib.types.str;
              default = "0400";
            };

            uploadAt = lib.mkOption {
              type = lib.types.enum [
                "pre-activation"
                "post-activation"
              ];
              default = if this ? usersModule then "post-activation" else "pre-activation";
            };

            service = lib.mkOption {
              type = lib.types.bool;
              default = false;
            };
          };
        }
      )
    );
    default = { };
  };

  config = lib.optionalAttrs (!(this ? usersModule)) {
    deployment.keys = lib.mkMerge (
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
  };
}
