{
  config,
  lib,
  n9,
  ...
}@args:

let
  # Provided by colmena:
  cfg = config.n9.security.secrets;
in
{
  imports = [ n9.inputs.colmena.nixosModules.deploymentOptions ];

  options.n9.security.secrets = lib.mkOption {
    type = lib.types.attrsOf (
      # @see home-manager/modules/lib/file-type.nix
      # @see https://colmena.cli.rs/unstable/reference/deployment.html
      lib.types.submodule (
        { name, config, ... }:
        {
          options.source = lib.mkOption {
            type = lib.types.str;
          };

          options.target = lib.mkOption {
            type = lib.types.str;
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

          config = {
            assertions = [
              {
                assertion = lib.hasPrefix "/" config.source;
                message = "source must be absolute";
              }
            ];

            target = lib.mkDefault name;
          };
        }
      )
    );

    default = { };
  };

  config.deployment.keys = lib.mkMerge (
    lib.mapAttrsToList (
      _: v:
      let
        name = builtins.baseNameOf v.target;
        destDir = builtins.dirOf v.target;
      in
      {
        ${name} = {
          keyFile = v.source;
          inherit (v)
            user
            group
            permission
            uploadAt
            ;
          inherit destDir;
        };
      }
    ) cfg
    ++ lib.flatten (
      n9.lib.forAllUsers config "security.secrets" (
        userName: v:
        lib.mapAttrsToList (
          _: v:
          let
            target = "${config.users.users.${userName}.home}/${v.target}";
            name = builtins.baseNameOf target;
            destDir = builtins.dirOf target;
          in
          {
            ${name} = {
              keyFile = v.source;
              user = userName;
              group = userName;
              inherit (v) permission;
              uploadAt = "post-activation";
              inherit destDir;
            };
          }
        ) v
      )
    )
  );
}
