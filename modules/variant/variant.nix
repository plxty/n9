{
  options,
  config,
  lib,
  n9,
  ...
}:

let
  rOptions = options; # r for reversed

  # [ { a = 1; } { a = 2; b = 3; } ] => { a = [ 1 2 ]; b = [ 3 ]; }
  groupBy = list: lib.foldAttrs (v: acc: [ v ] ++ acc) [ ] list;
in
{
  options.users = n9.mkAttrsOfSubmoduleOption (
    { options, ... }:
    {
      # For referencing config, please use rConfig..., this is just a snippet.
      options.variant = lib.mkOption {
        type = lib.types.submodule {
          options = rOptions.variant;
        };
        apply =
          _:
          let
            r = lib.mkAliasDefinitions options.variant;
          in
          assert r._type == "if" && r.condition && r.content._type == "merge";
          groupBy r.content.contents;
      };
    }
  );

  options.variant.get = {
    current = lib.mkOption {
      type = lib.types.enum [
        "nixos"
        "nix-darwin"
        "home-manager"
        "shell"
      ];
    };

    # TODO: .config?
    build = lib.mkOption {
      type = lib.types.package;
    };
  };

  config.variant =
    let
      r = groupBy (lib.mapAttrsToList (_: v: v.variant) config.users);
      merge = v: lib.mkMerge (lib.flatten v);
    in
    lib.mkMerge [
      (lib.genAttrs [ "nixos" "nix-darwin" "home-manager" ] (n: merge (r.${n} or [ ])))

      # This is fine, due to home-manager itself doesn't contains any system-wide stuff.
      # And with this one, we can type less with something like home-manager.users...
      (lib.genAttrs [ "nixos" "nix-darwin" ] (
        _:
        lib.concatMapAttrs (n: v: {
          home-manager.users.${n} = merge (v.variant.home-manager or [ ]);
        }) config.users
      ))
    ];
}
