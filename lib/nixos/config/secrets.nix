{
  config,
  lib,
  self,
  colmena,
  ...
}:

let
  cfg = config.n9.security.secrets;
  usercfg = self.lib.users "secrets" (v: v.n9.security.secrets) config;
in
{
  options.n9.security.secrets = lib.mkOption {
    type = lib.types.attrsOf (
      # @see home-manager/modules/lib/file-type.nix
      # @see https://colmena.cli.rs/unstable/reference/deployment.html
      lib.types.submodule (
        { name, ... }:
        {
          options.source = lib.mkOption {
            type = lib.types.str;
            apply =
              k:
              let
                basedir = "/home/byte/.n9/asterisk";
                abspath = "${basedir}/${k}";
              in
              assert lib.assertMsg (lib.hasPrefix "/" abspath) "wrong secret directory!";
              abspath;
          };

          options.target = lib.mkOption {
            type = lib.types.str;
            default = name;
          };

          options.user = lib.mkOption {
            type = lib.types.str;
            default = "root";
          };

          options.group = lib.mkOption {
            type = lib.types.str;
            default = "root";
          };

          options.permissions = lib.mkOption {
            type = lib.types.str;
            default = "0400";
          };

          options.uploadAt = lib.mkOption {
            type = lib.types.enum [
              "pre-activation"
              "post-activation"
            ];
            default = "pre-activation";
          };
        }
      )
    );

    default = { };
  };

  config.deployment.keys = lib.mkMerge (
    lib.mapAttrsToList (_: v: {
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
    }) cfg
    ++ lib.mapAttrsToList (
      n: keys:
      lib.concatMapAttrs (
        _: v:
        let
          target = "${config.users.users.${n}.home}/${v.target}";
        in
        {
          ${builtins.baseNameOf target} = {
            inherit (v) permissions;
            user = n;
            group = n;
            uploadAt = "post-activation";
            keyFile = v.source;
            destDir = builtins.dirOf target;
          };
        }
      ) keys
    ) usercfg
  );
}
