{
  options,
  config,
  lib,
  n9,
  inputs,
  this,
  ...
}:

let
  opt = options.n9.system;
  cfg = config.n9.system;

  commonModules = [
    inputs.colmena.nixosModules.deploymentOptions
    ../../home/config/users.nix
    ./keys.nix
    ./ssh-key.nix
    ./essentials.nix
  ];

  nixosModules = commonModules ++ [
    ../../nixos/config/disk.nix
    ../../nixos/config/network
    ../../nixos/config/sshd.nix
    ../../nixos/config/passwd.nix
    ../../nixos/config/ssh-key.nix
    ../../nixos/config/gnome.nix
    ../../nixos/config/boxes.nix
    ../../nixos/config/essentials.nix
  ];

  darwinModules = commonModules ++ [
    ../../darwin/config/essentials.nix
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
          osOptions = opt.${hostName};
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
      if this == "nixos" then
        (lib.trace "system: selecting nixos for ${hostName}" lib.nixosSystem) {
          inherit specialArgs;
          modules = nixosModules ++ hostModules;
        }
      else
        (lib.trace "system: selecting darwin for ${hostName}" inputs.nix-darwin.lib.darwinSystem) {
          inherit specialArgs;
          modules = darwinModules ++ hostModules;
        }
    );
  };
}
