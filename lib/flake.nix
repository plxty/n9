# Library of N9, devices should rely on this for modular.
# TODO: Mo(re)dules, when more devices.

{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    colmena = {
      url = "github:zhaofengli/colmena";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { nixpkgs, ... }@args:
    {
      lib = rec {
        # NixOS, Nix (For package manager only, use lib.mkNixPackager?):
        nixosSystem = import ./nixos.nix args;

        # Helpers of mine:
        patches =
          pkg: attrs:
          pkg.overrideAttrs (prev: {
            patches = (prev.patches or [ ]) ++ attrs;
          });
        patch = pkg: attr: patches pkg [ attr ];

        # https://gist.github.com/udf/4d9301bdc02ab38439fd64fbda06ea43
        # @see nixpkgs/lib/modules.nix, hasn't figure out the root cause...
        mkMergeTopLevel =
          names: attrs:
          with nixpkgs.lib;
          let
            # getAttrs' = names: attrs: genAttrs names (name: attrs.${name} or null);
            # names = flatten (map attrNames attrs.contents);
            toplevel = (mapAttrs (_: mkMerge) (foldAttrs (n: a: [ n ] ++ a) [ ] attrs));
          in
          getAttrs names toplevel;

        # For user modules, it fetch both system wide and user wide:
        # When system wide, the argument of `fn` will be null.
        forAllUsers =
          config: remains: system: fn:
          with nixpkgs.lib;
          let
            path = splitString "." remains;
            osConfig = {
              userName = null;
              config = getAttrFromPath path config;
            };
            userConfigs = mapAttrsToList (userName: v: {
              inherit userName;
              config = attrByPath ([ "modules" ] ++ path) null v;
            }) config.n9.users;
          in
          map (cfg: fn cfg.userName cfg.config) ((if system then [ osConfig ] else [ ]) ++ userConfigs);
      };
    };

  nixConfig = {
    substituters = [
      "https://mirror.sjtu.edu.cn/nix-channels/store"
      "https://mirrors.ustc.edu.cn/nix-channels/store"
      "https://mirrors.sustech.edu.cn/nix-channels/store"
    ];
  };
}
