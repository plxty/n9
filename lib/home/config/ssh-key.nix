{ config, lib, ... }:

let
  cfg = config.n9.security.ssh-key;

  # ssh-ed25519 ...
  typeOf =
    pubText:
    let
      format = lib.elemAt (lib.splitString " " pubText) 0;
      type = lib.removePrefix "ssh-" format;
    in
    assert lib.assertMsg (lib.hasPrefix "ssh-" format) "invalid ssh public format!";
    type;
in
{
  options.n9.security.ssh-key = {
    private = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
    };

    public = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
    };

    authorities = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
    };

    agents = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
    };
  };

  config = lib.mkMerge [
    (lib.mkIf (cfg.private != null) {
      n9.security.keys.".ssh/${builtins.baseNameOf cfg.private}".source = cfg.private;
    })

    (lib.mkIf (cfg.public != null) {
      home.file.".ssh/${typeOf cfg.public}".text = cfg.public;
    })
  ];
}
