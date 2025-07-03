{
  config,
  osConfig,
  lib,
  n9,
  this,
  hostName,
  userName,
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
                if userName == null then "${basedir}/${k}" else "${basedir}/${userName}/${k}";
            };

            target = lib.mkOption {
              type = lib.types.str;
              default = name;
              apply = v: if userName == null then v else "${osConfig.users.users.${userName}.home}/${v}";
            };

            user = lib.mkOption {
              type = lib.types.str;
              default = if userName == null then "root" else userName;
            };

            group = lib.mkOption {
              type = lib.types.str;
              default =
                if userName == null then
                  "root"
                else if this ? darwin then
                  "staff"
                else
                  userName;
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
              default = if userName == null then "pre-activation" else "post-activation";
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

  config = lib.optionalAttrs (!(this ? usersModule)) (
    lib.mkMerge [
      {
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
      }

      (lib.optionalAttrs (this ? nixos) {
        # have no much usage now... @see keyServiceModule
        systemd.paths = lib.mkMerge (
          lib.map (v: {
            "${builtins.baseNameOf v.target}-key".enable = v.service;
          }) keys
        );
        systemd.services = lib.mkMerge (
          lib.map (v: {
            "${builtins.baseNameOf v.target}-key".enable = lib.mkForce v.service;
          }) keys
        );
      })
    ]
  );
}
