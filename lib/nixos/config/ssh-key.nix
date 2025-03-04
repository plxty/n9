{config,lib, self ...}:

let
  mkUsers = self.lib.mkUsers "n9.security.ssh-key";
in
{
  options.n9.security.ssh-key = {
    public = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
    };

    private = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
    };

    agents = lib.mkOption {
      type = lib.types.listsOf lib.types.str;
      default = [];
    };
  };

  config = lib.mkMerge();
}
