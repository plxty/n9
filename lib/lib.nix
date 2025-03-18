{ inputs, ... }@args:

let
  inherit (inputs.nixpkgs) lib;
in
rec {
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

  # @see attrs = mkOptionType { ... }
  mkAttrsOption = lib.mkOption {
    type = lib.types.attrs // {
      merge = _: defs: recursiveMerge (lib.map (def: def.value) defs);
    };
    default = { };
  };

  # @see lib/nixos/config/users.nix
  # Returns { user: config; };
  # TODO: Fetch the name in a smarter way?
  users =
    name: attrFn: config:
    let
      val = lib.mapAttrs (_: attrFn) config.n9.users;
    in
    lib.traceSeq [ name val ] val;

  # Anyone has enabled?
  mkIfUsers = testFn: cfg: lib.mkIf (lib.any testFn (lib.attrValues cfg));

  # Replacing legacyPackages, for consistency. TODO: overriding in flake?
  mkPkgs =
    system:
    import inputs.nixpkgs {
      inherit system;
      overlays = [ (import ../pkgs/overlay.nix args) ];
    };

  # Network, maybe:
  mkCarrierOnlyNetwork =
    port:
    lib.recursiveUpdate {
      matchConfig.Name = port;
      networkConfig = {
        LinkLocalAddressing = "no";
        DHCP = "no";
      };
      linkConfig.RequiredForOnline = "carrier";
    };
}
