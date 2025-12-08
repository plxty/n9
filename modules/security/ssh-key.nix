{
  nodes,
  lib,
  n9,
  ...
}:

let
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
      nodes.${hostName}.users.${userName}.security.ssh-key.public
  );
in
{
  options.users = n9.options.mkAttrsOfSubmoduleOption { } (
    { name, config, ... }:
    let
      cfg = config.security.ssh-key;
    in
    {
      options.security.ssh-key = {
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

      config.security.keys = lib.mkIf (cfg.private != null) {
        ".ssh/${builtins.baseNameOf cfg.private}".source = cfg.private;
      };

      config.deployment.file = lib.mkIf (cfg.public != null) {
        ".ssh/id_${typeOf cfg.public}.pub".text = cfg.public;
      };

      config.variant.nixos = lib.mkIf (cfg.authorities != [ ] || cfg.agents != [ ]) {
        users.users.${name} = lib.mkIf (cfg.authorities != [ ]) {
          openssh.authorizedKeys.keys = publicOrFind cfg.authorities;
        };

        environment.etc = lib.mkIf (cfg.agents != [ ]) (
          lib.mergeAttrsList (
            lib.map (v: {
              "ssh/agent_keys.d/${name}" = {
                text = lib.concatStringsSep "\n" (publicOrFind cfg.agents);
                mode = "0644";
              };
            }) cfg.agents
          )
        );
      };
    }
  );
}
