{
  nodes,
  config,
  lib,
  n9,
  this,
  ...
}:

let
  cfg = config.n9.security.ssh-key;
  usercfg = n9.users "ssh-key" (v: v.n9.security.ssh-key) config;

  # ssh-ed25519 ...
  typeOf =
    pubText:
    let
      format = lib.elemAt (lib.splitString " " pubText) 0;
      type = lib.removePrefix "ssh-" format;
    in
    assert lib.assertMsg (lib.hasPrefix "ssh-" format) "invalid ssh public format!";
    type;

  publicOrFind = lib.map (
    keyOrPair:
    let
      # byte@evil (TODO: multiple public keys?)
      split = lib.splitString " " keyOrPair;
      pair = lib.splitString "@" keyOrPair;
      userName = lib.elemAt pair 0;
      hostName = lib.elemAt pair 1;
    in
    if lib.length split == 3 then
      keyOrPair
    else
      nodes.${hostName}.config.n9.users.${userName}.n9.security.ssh-key.public
  );
in
{
  options = lib.optionalAttrs (this ? usersModule) {
    n9.security.ssh-key = {
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
  };

  config =
    if (this ? usersModule) then
      lib.mkMerge [
        (lib.mkIf (cfg.private != null) {
          n9.security.keys.".ssh/${builtins.baseNameOf cfg.private}".source = cfg.private;
        })

        (lib.mkIf (cfg.public != null) {
          home.file.".ssh/${typeOf cfg.public}".text = cfg.public;
        })
      ]
    else if (this ? nixos) then
      n9.mkIfUsers (v: v.authorities != [ ] || v.agents != [ ]) usercfg {
        users.users = lib.mapAttrs (
          _: v:
          lib.mkIf (v.authorities != [ ]) {
            openssh.authorizedKeys.keys = publicOrFind v.authorities;
          }
        ) usercfg;

        # @see lib/nixos/config/sshd.nix
        environment.etc = lib.concatMapAttrs (
          n: v:
          lib.mkIf (v.agents != [ ]) {
            "ssh/agent_keys.d/${n}" = {
              text = lib.concatStringsSep "\n" (publicOrFind v.agents);
              mode = "0644";
            };
          }
        ) usercfg;

        # Hmmm, no disable.
        n9.services.sshd.enable = true;
      }
    else
      { };
}
