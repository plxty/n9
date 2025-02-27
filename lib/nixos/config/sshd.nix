{ config, lib, ... }:

let
  cfg = config.n9.services.sshd;
in
{
  options.n9.services.sshd = {
    enable = lib.mkEnableOption "sshd";

    port = lib.mkOption {
      type = lib.types.int;
      default = 22;
    };
  };

  config = lib.mkIf cfg.enable {
    services.openssh = {
      enable = true;
      ports = [ cfg.port ];
      authorizedKeysFiles = [ "/etc/ssh/agent_keys.d/%u" ];
    };
    networking.firewall.allowedTCPPorts = [ cfg.port ];

    # Fine-gran control of which user can use PAM to authorize things.
    security.pam = {
      sshAgentAuth = {
        enable = true;
        authorizedKeysFiles = [ "/etc/ssh/agent_keys.d/%u" ];
      };
      services.sudo.sshAgentAuth = true;
    };
  };
}
