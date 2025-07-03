{ lib, inputs, ... }@args:

rec {
  # Helpers of mine:
  patches =
    pkg: attrs:
    pkg.overrideAttrs (prev: {
      patches =
        (prev.patches or [ ])
        ++ (lib.map (v: if (lib.typeOf v) == "string" then ../pkgs/patches/${v}.patch else v) attrs);
    });
  patch = pkg: attr: patches pkg [ attr ];

  # Build the OS:
  systems =
    type: hosts:
    (lib.evalModules {
      specialArgs = args // {
        this.${type} = abort "gotcha";
      };
      modules = [
        ../modules/system
      ] ++ hosts;
    }).config.n9.system;

  # Like makeHive of colmena, and we call it hives :)
  # https://github.com/zhaofengli/colmena/blob/3ceec72cfb396a8a8de5fe96a9d75a9ce88cc18e/src/nix/hive/eval.nix#L184
  # Some features are missing, e.g. eval, they can be easily replaced by other commands.
  hives =
    nodes:
    let
      elem = builtins.elem;
      metaConfigKeys = [
        "name"
        "description"
        "machinesFile"
        "allowApplyAll"
      ];
    in
    rec {
      __schema = "v0.5";
      inherit nodes;
      toplevel = lib.mapAttrs (_: v: v.config.system.build.toplevel) nodes;
      deploymentConfig = lib.mapAttrs (_: v: v.config.deployment) nodes;
      deploymentConfigSelected = names: lib.filterAttrs (name: _: elem name names) deploymentConfig;
      evalSelected = names: lib.filterAttrs (name: _: elem name names) toplevel;
      evalSelectedDrvPaths = names: lib.mapAttrs (_: v: v.drvPath) (evalSelected names);
      metaConfig =
        lib.filterAttrs (n: v: elem n metaConfigKeys)
          (lib.evalModules {
            modules = [ inputs.colmena.nixosModules.metaOptions ];
          }).config;
    };

  # Shells, without S:
  hells =
    nixpkgs: shells: system:
    (lib.evalModules {
      specialArgs = args // {
        pkgs = mkNixpkgs nixpkgs system;
      };
      modules = [
        ../modules/shell
      ] ++ shells;
    }).config.n9.shell;

  # Hmm, why not?
  flatMap = fn: list: lib.flatten (lib.map fn list);
  flatMapAttrsToList = fn: attrs: lib.flatten (lib.mapAttrsToList fn attrs);

  # Path of me:
  dir = import ./dir.nix;

  # Niv sources:
  sources = import ./sources.nix;

  # Match or default:
  match =
    name: attrs: default:
    if (default == null || builtins.hasAttr name attrs) then attrs.${name} else default;

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
  mkAttrsOption =
    attrs:
    lib.mkOption (
      {
        type = lib.types.attrs // {
          merge = _: defs: recursiveMerge (lib.map (def: def.value) defs);
        };
        default = { };
      }
      // attrs
    );

  # @see lib/nixos/config/users.nix
  # Returns { user: config; };
  # TODO: Fetch the name in a smarter way?
  users =
    name: attrFn: config:
    lib.mapAttrs (_: attrFn) config.n9.users;

  # Anyone has enabled?
  mkIfUsers = testFn: cfg: lib.mkIf (lib.any testFn (lib.attrValues cfg));

  # Replacing legacyPackages, for consistency. TODO: overriding in flake?
  mkNixpkgs =
    nixpkgs: system:
    import nixpkgs {
      inherit system;
      overlays = [ (import ../pkgs/overlay.nix args) ];

      # It will get overriden by essentials, here just to help the shells.
      config.allowUnfree = true;
    };

  mkCrossNixpkgs =
    nixpkgs: system: target:
    import nixpkgs {
      inherit system;
      overlays = [ (import ../pkgs/overlay.nix args) ];
      crossSystem.config = target;
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
