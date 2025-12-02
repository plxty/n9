{
  config,
  lib,
  n9,
  ...
}:

let
  rConfig = config;
  cfg = config.users;

  assertSingleUser = prefix: {
    assertions = [
      {
        assertion = (lib.length (lib.attrNames cfg)) <= 1;
        message = "${prefix} cannot have multiple users defined!";
      }
    ];
  };
in
{
  options.users = n9.mkAttrsOfSubmoduleOption (
    { name, config, ... }:
    {
      options.home = lib.mkOption {
        type = lib.types.str;
        default = if rConfig.variant.is.nix-darwin then "/Users/${name}" else "/home/${name}";
      };

      config.variant = lib.mkMerge [
        {
          nixos = {
            users.groups.${name} = { };
            users.users.${name} = {
              isNormalUser = lib.mkDefault true;
              group = name;
              home = config.home;
              extraGroups = [
                "wheel"
                "dialout"
              ];
            };
          };
          nix-darwin = {
            users.users.${name} = {
              inherit name;
              home = config.home;
            };
            system.primaryUser = name;
          };
          home-manager.home = {
            username = name;
            homeDirectory = config.home;
            # @see modules/variant/home-manager.nix
            stateVersion = "25.05";
          };
        }

        rec {
          nixos.home-manager = {
            useUserPackages = true;
            useGlobalPkgs = true;
          };
          nix-darwin = nixos;
        }
      ];
    }
  );

  config.variant = {
    nix-darwin = assertSingleUser "nix-darwin";
    home-manager = assertSingleUser "home-manager";
  };
}
