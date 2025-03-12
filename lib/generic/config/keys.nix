{ lib, hostName, ... }@args:

let
  # The module system will try to deduce what you need from args, this will make
  # setting default value of arguments failed.
  userName = args.userName or null;
  osConfig = args.osConfig or { };
in
{
  # only options here, config is defined in lib/nixos/config/keys.nix:
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
                  basedir = "/home/byte/.n9/asterisk";
                  basedir' = "${basedir}/${hostName}";
                in
                assert lib.assertMsg (lib.hasPrefix "/" basedir) "wrong secret directory!";
                if userName == null then "${basedir'}/${k}" else "${basedir'}/${userName}/${k}";
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
              default = if userName == null then "root" else userName;
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
          };
        }
      )
    );
    default = { };
  };
}
