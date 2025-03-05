{ lib, ... }:

{
  options.n9.security.passwd = {
    file = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
    };
  };
}
