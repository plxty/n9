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
