{
  nodes,
  config,
  lib,
  n9,
  ...
}:

let
  usercfg = n9.users "ssh-key" (v: v.n9.security.ssh-key) config;

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
  config = lib.mkMerge [
    {
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
    }

    # Hmmm, no disable.
    (n9.mkIfUsers (v: v.authorities != [ ] || v.agents != [ ]) usercfg {
      n9.services.sshd.enable = true;
    })
  ];
}
