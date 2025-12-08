{
  config,
  lib,
  n9,
  pkgs,
  ...
}:

let
  rConfig = config;
in
{
  options.users = n9.mkAttrsOfSubmoduleOption { } (
    { config, ... }:
    let
      cfg = config.programs.code-server;
    in
    {
      options.programs.code-server = {
        enable = lib.mkEnableOption "code-server";

        package = lib.mkOption {
          type = lib.types.package;
          default = pkgs.code-server;
        };

        port = lib.mkOption {
          type = lib.types.int;
          default = 443;
        };

        passwd = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = null;
        };
      };

      config.security.keys.".keys/code-server-env" = lib.mkIf (cfg.enable && cfg.passwd != null) {
        source = cfg.passwd;
      };

      # https://github.com/NixOS/nixpkgs/blob/master/nixos/modules/services/web-apps/code-server.nix
      # Use direnv and envrc to manage tools like LSP or compiler.
      # TODO: Force code-server for only exploring.
      config.variant.home-manager.systemd.user = lib.mkIf cfg.enable {
        services.code-server = {
          Unit = {
            Description = "code-server";
          };
          Install = {
            WantedBy = [ "default.target" ];
          };
          Service = {
            EnvironmentFile = lib.mkIf (cfg.passwd != null) config.security.keys.".keys/code-server-env".target;
            ExecStart = pkgs.writers.writeBash "code-server" ''
              set -uex
              export PATH="${lib.makeBinPath [ pkgs.openssl ]}:$PATH"
              exec "${
                if rConfig.variant.is.nixos then "/run/wrappers/bin/code-server" else lib.getExe cfg.package
              }" \
                --auth=${if cfg.passwd != null then "password" else "none"} \
                --bind-addr=0.0.0.0:${builtins.toString cfg.port} \
                --cert \
                --ignore-last-opened \
                --disable-telemetry \
                --disable-update-check
            '';
            Restart = "on-failure";
          };
        };

        # TODO: To separate file?
        startServices = "sd-switch";
      };

      config.variant.nixos.security.wrappers.code-server = lib.mkIf cfg.enable {
        owner = "root";
        group = "root";
        capabilities = "cap_net_bind_service=+ep";
        source = lib.getExe cfg.package;
      };
    }
  );
}
