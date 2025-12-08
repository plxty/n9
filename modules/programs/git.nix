{
  lib,
  n9,
  pkgs,
  ...
}:

{
  options.users = n9.mkAttrsOfSubmoduleOption { } (
    { config, ... }:
    let
      cfg = config.programs.git;
    in
    {
      options.programs.git = {
        package = lib.mkOption {
          type = lib.types.package;
          default = pkgs.git;
        };

        cache = lib.mkEnableOption "gitcache";
      };

      # TODO: Bash?
      config.variant.home-manager.programs.fish.shellAliases = lib.mkIf cfg.cache {
        # Replace with wrapper will slow down the completion of fish, which is
        # quite annoying, therefore we just alias it for interactive use.
        git = "${lib.getExe pkgs.gitcache} git";
      };

      config.variant.home-manager.programs.git = {
        enable = true;
        inherit (cfg) package;

        settings = {
          user = {
            name = "Zigit Zo";
            email = "byte@kei.network";
            useConfigOnly = true;
          };
          init.defaultBranch = "main";
        };

        signing.format = "ssh";
      };
    }
  );
}
