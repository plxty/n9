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

  # Hmm, why not?
  flatMap = fn: list: lib.flatten (lib.map fn list);

  # Like recursiveUpdate, but also handle the lists concation:
  # When using mergeAttrs, recursiveUpdate or other merging functions, you'd
  # better think twice of what you want, and what is the inner types you're
  # dealing with.
  # https://stackoverflow.com/a/54505212
  recursiveMerge =
    attrList:
    let
      f =
        attrPath:
        lib.zipAttrsWith (
          n: values:
          if lib.tail values == [ ] then
            lib.head values
          else if lib.all lib.isList values then
            lib.unique (lib.concatLists values)
          else if lib.all lib.isAttrs values then
            f (attrPath ++ [ n ]) values
          else
            lib.last values
        );
    in
    f [ ] attrList;

  # @see lib/nixos/config/users.nix
  # Returns { user: config; };
  # TODO: Fetch the name in a smarter way?
  users =
    name: attrFn: config:
    let
      val = lib.mapAttrs (_: v: attrFn v.imports) config.n9.users;
    in
    lib.traceSeq [ name val ] val;

  # Anyone has enabled?
  mkIfUsers = testFn: cfg: lib.mkIf (lib.any testFn (lib.attrValues cfg));
}
