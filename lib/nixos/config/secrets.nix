{
  config,
  lib,
  n9,
  ...
}:

let
  cfg = config.n9.security.secrets;
  mkUsers = n9.lib.mkUsers config "n9.security.secrets";
in
{
  imports = [ n9.inputs.colmena.nixosModules.deploymentOptions ];

  options.n9.security.secrets = lib.mkOption {
    type = lib.types.attrsOf (
      # @see home-manager/modules/lib/file-type.nix
      # @see https://colmena.cli.rs/unstable/reference/deployment.html
      lib.types.submodule (
        { name, ... }:
        {
          options.source = lib.mkOption {
            type = lib.types.str;
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
    ++ mkUsers (
      userName: keys:
      n9.lib.flatMapAttrsToList (
        _: v:
        let
          target = "${config.users.users.${userName}.home}/${v.target}";
        in
        {
          ${builtins.baseNameOf target} = {
            inherit (v) permissions;
            user = userName;
            group = userName;
            uploadAt = "post-activation";
            keyFile = v.source;
            destDir = builtins.dirOf target;
          };
        }
      ) keys
    )
  );
}
