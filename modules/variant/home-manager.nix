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
  opt = options.variant.home-manager;
  cfg = config.variant.home-manager;

  mkHomeManagerConfiguration =
    modules:
    inputs.home-manager.lib.homeManagerConfiguration {
      inherit pkgs modules;
    };
in
{
  # Here we will lost many config.xxx sections, and only options are here,
  # therefore one more evaluation to final module is neccessary now.
  # TODO: this is quite tricky, right :?
  # The `submodule` here is to make mkAliasDefinitions to work (wrap as an option).
  options.variant.home-manager = lib.mkOption {
    type = lib.types.submodule {
      options = n9.mkOptionsFromConfig (mkHomeManagerConfiguration [
        {
          # It's only to "bypass" the home-manager, to let us have a proper options.
          home = {
            username = lib.mkDefault "whoami";
            homeDirectory = lib.mkDefault "/tmp";
            stateVersion = "25.05";
          };
        }
      ]);
    };
    # We just want it for a little better debugging:
    apply = _: (mkHomeManagerConfiguration [ (lib.mkAliasDefinitions opt) ]).config;
  };

  config.variant.build = lib.mkIf config.variant.is.home-manager cfg.home.activationPackage;
}
