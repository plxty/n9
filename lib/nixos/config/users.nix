{
  options,
  config,
  lib,
  pkgs, # MUST have, maybe the module system is using `functionArgs`?
  n9,
  ...
}@args:
let
  cfg = config.n9.users;

  getAttrs' =
    names: attrs: lib.genAttrs (lib.filter (name: attrs ? ${name}) names) (name: attrs.${name});

  homeAttrNames = [
    "home"
    "programs"
  ];
in
{
  # @see https://nixos-and-flakes.thiscute.world/other-usage-of-flakes/module-system
  imports = [
    n9.inputs.home-manager.nixosModules.home-manager
  ];

  options.n9.users = lib.mkOption {
    type = lib.types.attrsOf (
      lib.types.submodule {
        # Free type modules, we're making our own version:
        options =
          {
            modules = lib.mkOption {
              type =
                let
                  inner = lib.types.submodule {
                    options =
                      (lib.genAttrs homeAttrNames (
                        _:
                        lib.mkOption {
                          type = lib.types.attrs;
                          default = { };
                        }
                      ))
                      // {
                        inherit (options) n9;
                      };
                  };
                in
                lib.types.listOf (
                  lib.types.oneOf [
                    (lib.types.functionTo inner)
                    inner
                  ]
                );
              default = [ ];
            };
          }
          # Exposed from inner, for other modules to use:
          # TODO: Filter only for users?
          // options.n9;
      }
    );
  };

  config = n9.lib.mkMergeTopLevel [ "home-manager" "users" ] (
    (lib.optional (cfg != { }) {
      # https://discourse.nixos.org/t/users-users-name-packages-vs-home-manager-packages/22240/2
      home-manager.useUserPackages = true;
      home-manager.useGlobalPkgs = true;

      # disable root for security:
      users.users.root.hashedPassword = "!";
    })
    ++ lib.flatten (
      lib.mapAttrsToList (
        userName: v:
        [
          {
            users.groups.${userName}.gid = null;

            users.users.${userName} = {
              isNormalUser = true;
              uid = null;
              group = userName;
              extraGroups = [ "wheel" ];
            };

            # There's no nixosSystem like functions...
            # We place the bootstrap here, TODO: to essential.nix?
            home-manager.users.${userName} = {
              home.username = userName;
              home.stateVersion = "25.05";
            };
          }
        ]
        ++ lib.map (
          m:
          let
            attrs = lib.traceVal (
              if lib.isFunction m then m (lib.recursiveUpdate args { n9.userName = userName; }) else m
            );
          in
          {
            home-manager.users.${userName} = getAttrs' homeAttrNames attrs;
            n9.users.${userName} = attrs.n9;
          }
        ) v.modules
      ) cfg
    )
  );
}
