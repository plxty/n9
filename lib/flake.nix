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
        # Must make the config "static", i.e. the fields must be known by nix,
        # for example `config = genAttrs` will cause inifinte recursion, while
        # `config = { services = ... }` will work.
        # This might because the module's `options` is "part of" the `config`
        # argument, therefore accessing config is like holding a big lock with
        # options, which we're still defininig.
        #
        # The mkMergeTopLevel requires a "static" configuration as well, that
        # is the inner configurations MUST contains the given toplevel attrs.
        # There's currently no way to make it dynamic here.
        mkMergeTopLevel =
          names: attrs:
          with nixpkgs.lib;
          getAttrs names (mapAttrs (k: mkMerge) (foldAttrs (n: a: [ n ] ++ a) [ ] attrs));

        # Make foldFn [(mapFn user.name user.cfg), (mapFn user.name user.cfg)]:
        # TODO: Optimise for better usage...
        mkUsers =
          config: pathStr: mapFn:
          with nixpkgs.lib;
          mapAttrsToList (
            userName: v:
            let
              path = splitString "." pathStr;
              inner = getAttrFromPath ([ "modules" ] ++ path) v;
              print = mapAttrsToList (
                k: v:
                "${k}="
                + (
                  if typeOf v == "string" then
                    v
                  else if typeOf v == "bool" then
                    boolToString v
                  else
                    "<uneval>"
                )
              ) inner;
              msg = "evaluating: n9.users.${userName}.${pathStr} <- ${concatStringsSep "," print}";
            in
            trace msg mapFn userName inner
          ) config.n9.users;

        # Like mkMerge:
        mkMergeUsers =
          config: pathStr: mapFn:
          nixpkgs.lib.mergeAttrsList (mkUsers config pathStr mapFn);

        # Why there's no flatmap?
        flatMapAttrsToList = fn: attrs: nixpkgs.lib.flatten (nixpkgs.lib.mapAttrsToList fn attrs);
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
