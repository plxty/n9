{
  config,
  osConfig,
  lib,
  pkgs,
  this,
  ...
}:

let
  cfg = config.n9.essentials.home;
in
{
  options.n9.essentials.home.enable = lib.mkOption {
    type = lib.types.bool;
    default = true;
  };

  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      {
        home.packages = with pkgs; [
          wget
          p7zip
          unrar
          jq
          yq
          python3
          cached-nix-shell
          nix-tree
          pstree
          binutils
          coreutils
          moreutils
          file
          dig
          binwalk
          gitoxide
          bc
          ncdu
          nix-prefetch-scripts
          rsync
        ];

        programs.ssh = {
          enable = true;
          addKeysToAgent = "9h";
          forwardAgent = true;
          includes = [ "config.d/hosts" ];
        };

        programs.git = {
          enable = true;
          userName = "Zigit Zo";
          userEmail = "byte@pen.guru";
          signing.format = "ssh";
          extraConfig = {
            user.useConfigOnly = true;
            init.defaultBranch = "main";
          };
        };

        home.file.".config/nixpkgs/config.nix".text = ''
          { allowUnfree = true; }
        '';

        home.file.".local/share/nix/trusted-settings.json" =
          let
            # using osConfig.nix.settings.substituters directly will introduce an
            # extra defult cache.nixos.org, we use this way to avoid it... TODO
            # make a osOptions to obtain the raw values?
            inherit ((import ../../../flake.nix).nixConfig) substituters;
          in
          {
            text = ''
              {
                "substituters": { "${lib.concatStringsSep " " substituters}": true }
              }
            '';
            force = true;
          };

        home.stateVersion = "25.05";
      }

      # Don't use mkIf here due to the mkIf will try to resolve what doesn't exists.
      (lib.optionalAttrs (this == "nixos") {
        home.packages = with pkgs; [
          strace
          sysstat
          lm_sensors
          bpftrace
          osConfig.boot.kernelPackages.perf
          smartmontools
        ];

        services.ssh-agent.enable = true;
      })
    ]
  );
}
