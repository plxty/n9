{
  config,
  lib,
  n9,
  inputs,
  this,
  ...
}:

let
  cfg = config.n9.system;

  sharedModules = [
    ../nix # contains overlays
    inputs.colmena.nixosModules.deploymentOptions
    ./users.nix
    ./keys.nix
    ./ssh-key.nix
  ];
in
{
  # funny: n9.system.evil.n9.users.byte.n9.security.keys
  options.n9.system = lib.mkOption {
    type = lib.types.attrsOf lib.types.unspecified;
    apply = lib.mapAttrs (
      hostName: modules:
      let
        specialArgs = {
          # Don't pollute with argument "config" and "options", like in users.nix:
          inherit
            n9
            inputs
            this
            ;
          nodes = cfg;
          osConfig = cfg.${hostName}.config;
        };

        hostModules = [
          (
            { pkgs, ... }:
            {
              config = {
                # To satisfy the colmena...
                _module.args.name = hostName;
                networking.hostName = hostName;

                # https://github.com/luishfonseca/nixos-config/blob/main/modules/upgrade-diff.nix
                # https://github.com/nix-darwin/nix-darwin/blob/e04a388232d9a6ba56967ce5b53a8a6f713cdfcf/modules/system/activation-scripts.nix#L114
                system.activationScripts.postActivation = {
                  # supportsDryActivation = true; # TODO: doesn't exist in darwin...
                  text = ''
                    ${pkgs.nvd}/bin/nvd --nix-bin-dir=${pkgs.nix}/bin diff /run/current-system "$systemConfig"
                  '';
                };
              };
            }
          )
          modules
        ];
      in
      if this ? nixos then
        (lib.trace "system: selecting nixos for ${hostName}" lib.nixosSystem) {
          inherit specialArgs;
          modules = sharedModules ++ [ ./nixos ] ++ hostModules;
        }
      else if this ? darwin then
        (lib.trace "system: selecting darwin for ${hostName}" inputs.nix-darwin.lib.darwinSystem) {
          inherit specialArgs;
          modules = sharedModules ++ [ ./darwin ] ++ hostModules;
        }
      else
        abort "unsupported system!"
    );
  };
}
