{ nixpkgs, ... }@inputs:

let
  inherit (nixpkgs) lib;
in
rec {
  # NixOS, Nix (For package manager only, use lib.mkNixPackager?):
  nixosSystem = import ./nixos.nix inputs;

  # Helpers of mine:
  patches =
    pkg: attrs:
    pkg.overrideAttrs (prev: {
      patches = (prev.patches or [ ]) ++ attrs;
    });
  patch = pkg: attr: patches pkg [ attr ];

  # Make foldFn [(mapFn user.name user.cfg), (mapFn user.name user.cfg)]:
  # @see lib/nixos/config/users.nix
  # TODO: Optimise for better usage...
  mkUsers =
    config: pathStr: mapFn:
    lib.mapAttrsToList (
      userName: v:
      let
        path = lib.splitString "." pathStr;
        inner = lib.getAttrFromPath ([ "modules" ] ++ path) v;
        print = lib.mapAttrsToList (
          k: v:
          "${k}="
          + (
            if lib.typeOf v == "string" then
              v
            else if lib.typeOf v == "bool" then
              lib.boolToString v
            else
              "<uneval>"
          )
        ) inner;
        msg = "evaluating: n9.users.${userName}.${pathStr} <- ${lib.concatStringsSep "," print}";
      in
      lib.trace msg mapFn userName inner
    ) config.n9.users;

  # Like mkMerge:
  mkMergeUsers =
    config: pathStr: mapFn:
    lib.mergeAttrsList (mkUsers config pathStr mapFn);

  # If any of the options in users are true:
  mkIfUsers =
    config: pathStr: testFn:
    lib.any lib.id (mkUsers config pathStr testFn);

  # A flatten wrapper:
  mkFlattenUsers =
    config: pathStr: mapFn:
    lib.flatten (mkUsers config pathStr mapFn);
}
