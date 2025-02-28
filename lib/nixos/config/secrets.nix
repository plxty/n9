{
  config,
  lib,
  n9,
  ...
}:

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

          config.target = lib.mkDefault name;
        }
      )
    );

    default = { };
  };

  config.deployment.keys = lib.mkMerge (
    lib.flatten (
      n9.lib.forAllUsers config "n9.security.secrets" true (
        userName: keys:
        lib.mapAttrsToList (
          _: v:
          let
            # Force override option if user, TODO: better idea?
            isUser = userName != null;
            target = if isUser then "${config.users.users.${userName}.home}/${v.target}" else v.target;
            user = if isUser then userName else v.user;
            group = if isUser then userName else v.group;
            uploadAt = if isUser then "post-activation" else v.uploadAt;

            # To colmena:
            name = builtins.baseNameOf target;
            destDir = builtins.dirOf target;
          in
          {
            ${name} = {
              keyFile = v.source;
              inherit
                user
                group
                uploadAt
                destDir
                ;
              inherit (v) permissions;
            };
          }
        ) keys
      )
    )
  );
}
