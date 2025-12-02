{
  config,
  lib,
  n9,
  pkgs,
  ...
}:

let
  # TODO: Move to ssh-server?
  cfg = config.programs.ssh;

  agents = [ "/etc/ssh/agent_keys.d/%u" ];
in
{
  options.programs.ssh.server = {
    enable = lib.mkEnableOption "sshd-server";

    port = lib.mkOption {
      type = lib.types.int;
      default = 22;
    };
  };

  options.users = n9.mkAttrsOfSubmoduleOption (
    { name, config, ... }:
    let
      cfg = config.programs.ssh;
    in
    {
      options.programs.ssh = {
        package = lib.mkOption {
          type = lib.types.package;
          default = pkgs.openssh;
        };
      };

      config.environment.packages = [
        cfg.package
        pkgs.sshpass
      ];

      config.variant = {
        home-manager.programs.ssh = {
          enable = true;
          enableDefaultConfig = false;
          matchBlocks."*" = {
            addKeysToAgent = "9h";
            forwardAgent = true;
          };
          includes = [ "config.d/*" ];

          # Legacy, but needs for intranet:
          extraConfig = ''
            GSSAPIAuthentication yes
            GSSAPIDelegateCredentials no
            HostKeyAlgorithms +ssh-rsa
            PubkeyAcceptedKeyTypes = +ssh-rsa
          '';
        };

        home-manager.services.ssh-agent.enable = true;
        nix-darwin.home-manager.users = {
          # Not for nix-darwin:
          ${name}.services.ssh-agent.enable = lib.mkForce false;
        };
      };
    }
  );

  config.variant.nixos = lib.mkIf cfg.server.enable {
    services.openssh = {
      enable = true;
      ports = [ cfg.server.port ];
      authorizedKeysFiles = agents;
    };

    # TODO: NIC Port control?
    networking.firewall.allowedTCPPorts = [ cfg.server.port ];

    # Fine-gran control of which user can use PAM to authorize things.
    security.pam = {
      sshAgentAuth = {
        enable = true;
        authorizedKeysFiles = agents;
      };
      services.sudo.sshAgentAuth = true;
    };
  };
}
