{
  name,
  options,
  config,
  lib,
  n9,
  pkgs,
  inputs,
  ...
}:

let
  opt = options.variant.nixos;
  cfg = config.variant.nixos;

  mkNixOSConfiguration =
    modules:
    lib.nixosSystem {
      modules = [
        # Manage config.{disko,home-manager} as well:
        inputs.disko.nixosModules.disko
        inputs.home-manager.nixosModules.default
      ]
      ++ modules;
    };
in
{
  # FIXME: imports will not work as `variant.nixos.imports`, because you can't
  # import things outside the submodule's "modules".
  # @see https://github.com/NixOS/nixpkgs/issues/70638
  options.variant.nixos = lib.mkOption {
    type = lib.types.submodule {
      options = n9.mkOptionsFromConfig (mkNixOSConfiguration [ ]);
    };
    apply =
      _:
      (mkNixOSConfiguration [
        # TODO: Move to somewhere default config?
        {
          nixpkgs.pkgs = pkgs;
          hardware.enableRedistributableFirmware = true;
          networking = {
            hostName = name;
            hostId = builtins.substring 63 8 (builtins.hashString "sha512" name);
          };
          systemd.coredump.extraConfig = "Storage=journal";
          # To run "native" linux elf, such as vscode remote server:
          programs.nix-ld = {
            enable = true;
            libraries = with pkgs; [
              # https://youtrack.jetbrains.com/issue/CPP-44987
              icu
            ];
          };
          system.stateVersion = "25.05";
        }
        # The hardware-configuration.nix, an "backdoor" of imports :/
        # TODO: Define a options of imports? It's weird of course.
        config.hardware.configuration
        # Real definitions :)
        (lib.mkAliasDefinitions opt)
      ]).config;
  };

  config.variant.build = lib.mkIf config.variant.is.nixos cfg.system.build.toplevel;
}
