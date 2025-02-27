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
          with nixpkgs.lib;
          names: attrs: getAttrs names (mapAttrs (k: v: mkMerge v) (foldAttrs (n: a: [ n ] ++ a) [ ] attrs));

        # For user modules:
        forAllUsers =
          with nixpkgs.lib;
          config: remains: fn:
          let
            path = splitString "." remains;
          in
          mapAttrsToList (userName: v: fn userName (attrByPath path null v)) config.n9.users;
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
