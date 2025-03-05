{ nixpkgs, ... }:

file:

# For reverting to nixosSystem, commit 0dfc786daefb441c8e14b3f97fa3393847d1de9d
let
  inherit (nixpkgs) lib;

  # Trying to find { system } within the modules, it now MUST be a simple attrs,
  # because without system we can't provide the "pkgs" argument to the module.
  foldSystem =
    modules:
    lib.fold
      (
        a: b:
        if lib.isAttrs a && a ? system then
          {
            inherit (a) system;
            modules = b.modules ++ [ (lib.removeAttrs a "system") ];
          }
        else
          {
            inherit (b) system;
            modules = b.modules ++ [ a ];
          }
      )
      {
        system = null;
        modules = [ ];
      }
      modules;

  # Feed the colmena:
  apply =
    hostName:
    { system, modules }:
    let
      system' = if system == null then "x86_64-linux" else system;
      system'' = lib.trace "selecting ${system'} for ${hostName}" system';
    in
    {
      meta.nodeNixpkgs.${hostName} = nixpkgs.legacyPackages.${system''};
      meta.nodeSpecialArgs.${hostName} = { inherit hostName; };

      ${hostName}.imports = [
        # options
        ./nixos/config/disk.nix
        ./nixos/config/sshd.nix
        ./nixos/config/users.nix
        ./common/config/secrets.nix
        ./nixos/config/secrets.nix
        ./nixos/config/passwd.nix
        ./nixos/config/ssh-key.nix
        ./nixos/config/pop-shell.nix
        ./nixos/config/boxes.nix

        # configs
        ./nixos/essential.nix
      ] ++ modules;
    };

  inherit
    (lib.evalModules {
      modules = [
        {
          options.n9.os = lib.mkOption {
            type = lib.types.attrsOf (
              lib.types.submodule (
                { config, name, ... }:
                {
                  # FIXME: The imports are "fake" here, to keep user level API
                  # "consistency", archiving a real system option is hard.
                  options.imports = lib.mkOption {
                    type = lib.types.listOf lib.types.unspecified;
                    apply = v: apply name (foldSystem v);
                  };
                }
              )
            );
          };
        }

        # Top level, here we are!
        file
      ];
      class = "n9.os";
    })
    config
    ;
in
lib.mapAttrsToList (_: v: v.imports) config.n9.os
