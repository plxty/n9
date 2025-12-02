{
  config,
  lib,
  n9,
  ...
}:

let
  cfg = config.environment.packages;
in
{
  options.environment.packages = lib.mkOption {
    type = lib.types.listOf lib.types.package;
    default = [ ];
  };

  options.users = n9.mkAttrsOfSubmoduleOption (
    { config, ... }:
    let
      cfg = config.environment.packages;
    in
    {
      options.environment.packages = lib.mkOption {
        type = lib.types.listOf lib.types.package;
        default = [ ];
      };

      config.variant.home-manager.home.packages = cfg;
    }
  );

  config.variant = rec {
    nixos.environment.systemPackages = cfg;
    nix-darwin = nixos;
    shell.packages = cfg;
  };
}
