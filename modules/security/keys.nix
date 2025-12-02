{
  name,
  config,
  lib,
  pkgs,
  ...
}:

let
  # Merge both users and system config:
  cfg = lib.mergeAttrsList [
    config.security.keys
    (lib.concatMapAttrs (_: v: v.security.keys) config.users)
  ];
  rConfig = config;

  mkSecurityKeysOption =
    userName: config:
    lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submodule [
          (
            { name, ... }:
            {
              # @see home-manager/modules/lib/file-type.nix
              # @see https://colmena.cli.rs/unstable/reference/deployment.html
              options = {
                source = lib.mkOption {
                  type = lib.types.str;
                  apply =
                    source:
                    let
                      path = "${rConfig.deployment.rootAbsolute}/asterisk/${hostName}";
                    in
                    if userName == null then "${path}/${source}" else "${path}/${userName}/${source}";
                };
                target = lib.mkOption {
                  type = lib.types.str;
                  default = name;
                  apply = target: if userName == null then target else "${config.home}/${target}";
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
                    else if pkgs.stdenv.isDarwin then
                      "staff"
                    else
                      userName;
                };
                permissions = lib.mkOption {
                  type = lib.types.str;
                  default = "0600";
                };
                uploadAt = lib.mkOption {
                  type = lib.types.enum [
                    "pre-activation"
                    "post-activation"
                  ];
                  default = if userName == null then "pre-activation" else "post-activation";
                };
              };
            }
          )
        ]
      );
      default = { };
    };

  # Prevent shadowing:
  hostName = name;
in
{
  options.security.keys = mkSecurityKeysOption null config;

  options.users = lib.mkOption {
    type = lib.types.attrsOf (
      lib.types.submodule (
        { name, config, ... }:
        {
          options.security.keys = mkSecurityKeysOption name config;
        }
      )
    );
  };

  config.deployment.keys = lib.mapAttrs (_: v: {
    inherit (v)
      user
      group
      permissions
      uploadAt
      ;
    keyFile = v.source;
    name = builtins.baseNameOf v.target;
    destDir = builtins.dirOf v.target;
  }) cfg;
}
