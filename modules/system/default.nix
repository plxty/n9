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
    inputs.colmena.nixosModules.deploymentOptions
    ./users.nix
    ./keys.nix
    ./ssh-key.nix
    ../nix
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
            hostName
            this
            ;
          userName = null; # make some "generic" modules working
          nodes = cfg;
          osConfig = cfg.${hostName};
        };

        hostModules = [
          {
            # To satisfy the colmena...
            config._module.args.name = hostName;
          }
          modules
        ];
      in
      if this ? nixos then
        (lib.trace "system: selecting nixos for ${hostName}" lib.nixosSystem) {
          inherit specialArgs;
          modules =
            sharedModules
            ++ [
              ./nixos/disk.nix
              ./nixos/network
              ./nixos/sshd.nix
              ./nixos/passwd.nix
              ./nixos/gnome
              ./nixos/boxes.nix
              ./nixos/essentials.nix
            ]
            ++ hostModules;
        }
      else if this ? darwin then
        (lib.trace "system: selecting darwin for ${hostName}" inputs.nix-darwin.lib.darwinSystem) {
          inherit specialArgs;
          modules =
            sharedModules
            ++ [
              ./darwin/essentials.nix
            ]
            ++ hostModules;
        }
      else
        abort "unsupported system!"
    );
  };
}
