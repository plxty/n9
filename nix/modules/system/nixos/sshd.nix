{ config, lib, ... }:

let
  cfg = config.n9.services.sshd;
  agents = [ "/etc/ssh/agent_keys.d/%u" ];
in
{
  options.n9.services.sshd = {
    enable = lib.mkEnableOption "sshd";

    port = lib.mkOption {
      type = lib.types.int;
      default = 22;
    };
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
      services.openssh = {
        enable = true;
        ports = [ cfg.port ];
        authorizedKeysFiles = agents;
      };

      # TODO: NIC Port control?
      networking.firewall.allowedTCPPorts = [ cfg.port ];

      # Fine-gran control of which user can use PAM to authorize things.
      security.pam = {
        sshAgentAuth = {
          enable = true;
          authorizedKeysFiles = agents;
        };
        services.sudo.sshAgentAuth = true;
      };
    })

    # When sshd is disabled, we make the local deployment work:
    { deployment.allowLocalDeployment = lib.mkDefault (!cfg.enable); }
  ];
}
