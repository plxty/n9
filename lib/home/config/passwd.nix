{ lib, userName, ... }:

{
  options.n9.security.passwd = {
    file = lib.mkOption {
      # To keep consistency of generic/config/keys.nix:
      type = lib.types.nullOr lib.types.str;
      default = "${userName}/passwd";
    };
  };
}
