{
  options,
  config,
  lib,
  n9,
  pkgs,
  inputs,
  ...
}:

let
  opt = options.variant.nix-darwin;
  cfg = config.variant.nix-darwin;

  isNixDarwin = config.variant.get.current == "nix-darwin";

  mkNixDrwinConfiguration =
    modules:
    inputs.nix-darwin.lib.darwinSystem {
      modules = [
        inputs.home-manager.darwinModules.default
      ]
      ++ modules;
    };
in
{
  # Why not making variant = if isNixDarwin then {...} else if {...} ...?
  # Because we just want less if... unless there's no other better way :/
  options.variant.is.nix-darwin = lib.mkOption {
    type = lib.types.bool;
    default = isNixDarwin;
  };

  options.variant.nix-darwin = lib.mkOption {
    type = lib.types.submodule {
      options = n9.mkOptionsFromConfig (mkNixDrwinConfiguration [ ]);
    };
    apply =
      _:
      (mkNixDrwinConfiguration [
        # TODO: Move to other modules:
        {
          nixpkgs.pkgs = pkgs;
          # Nerd fonts can be installed by iterm2.
          fonts.packages = with pkgs; [
            jetbrains-mono
            source-code-pro
          ];
          # Appearence of macOS:
          system.defaults.dock = {
            mineffect = "scale";
            autohide = true;
          };
          system.defaults.CustomSystemPreferences = {
            # https://github.com/runjuu/InputSourcePro/issues/24#issuecomment-2978745464
            "/Library/Preferences/FeatureFlags/Domain/UIKit.plist" = {
              redesigned_text_cursor.Enabled = false;
            };
          };
          system.stateVersion = 6;
        }
        (lib.mkAliasDefinitions opt)
      ]).config;
  };

  config.variant.get.build = lib.mkIf isNixDarwin cfg.system.build.toplevel;
}
