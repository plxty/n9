{ lib, inputs, ... }:

let
  n9 = {
    sources = import ./sources.nix;

    packages = rec {
      patches =
        pkg: attrs:
        pkg.overrideAttrs (prev: {
          patches =
            (prev.patches or [ ])
            ++ (lib.map (v: if (lib.typeOf v) == "string" then ../pkgs/patches/${v}.patch else v) attrs);
        });
      patch = pkg: attr: patches pkg [ attr ];

      assureVersion =
        pkg: version: attrsOrFn:
        let
          attrs =
            final: prev:
            if lib.isFunction attrsOrFn then
              if lib.isFunction (attrsOrFn { }) then attrsOrFn prev final else attrsOrFn prev
            else
              attrsOrFn;
        in
        if lib.versionOlder pkg.version version then
          pkg.overrideAttrs (final: prev: (attrs final prev) // { inherit version; })
        else
          lib.trace "package ${pkg.pname} already satisfied version ${version}, may remove the assureVersion" pkg;
    };

    options = {
      mkAttrsOfSubmoduleOption =
        attrs: modules: lib.mkOption (attrs // { type = lib.types.attrsOf (lib.types.submodule modules); });
      mkAttrsOfSubmoduleWithOption =
        attrs: modules:
        lib.mkOption (attrs // { type = lib.types.attrsOf (lib.types.submoduleWith modules); });

      mkOptionsFromConfig =
        { options, ... }:
        (lib.removeAttrs options [ "_module" ])
        // {
          _module = lib.removeAttrs options._module [
            "check"
            "freeformType"
          ];
        };
    };

    modules = rec {
      mkWorld =
        module-list: modules:
        let
          theWorld =
            n:
            n9.mkAttrsOfSubmoduleWithOption { default = { }; } {
              modules = module-list ++ [
                { config.variant.get.current = n; }
              ];
              shorthandOnlyDefinesConfig = true;
              specialArgs = { inherit nodes n9 inputs; };
            };
          nodes' = lib.evalModules {
            modules = [
              { options.n9 = lib.genAttrs [ "nixos" "nix-darwin" "home-manager" "shell" ] theWorld; }
            ]
            ++ modules;
          };
          # Ignore the system types:
          nodes = lib.concatMapAttrs (_: lib.id) nodes'.config.n9;
        in
        nodes;
      mkHosts =
        module-list: modules:
        let
          nodes = lib.mapAttrs (_: v: { config = v; }) (mkWorld module-list modules);
          elem = lib.elem;
          metaConfigKeys = [
            "name"
            "description"
            "machinesFile"
            "allowApplyAll"
          ];
        in
        # https://github.com/zhaofengli/colmena/blob/3ceec72cfb396a8a8de5fe96a9d75a9ce88cc18e/src/nix/hive/eval.nix#L184
        rec {
          __schema = "v0.5";
          inherit nodes;
          toplevel = lib.mapAttrs (_: v: v.config.variant.get.build) nodes;
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
      mkEnvs =
        module-list: modules:
        lib.genAttrs
          [
            "x86_64-linux"
            "aarch64-linux"
            "aarch64-darwin"
          ]
          (
            system:
            let
              withSystem.options.n9.shell = n9.mkAttrsOfSubmoduleOption { } { nixpkgs.hostPlatform = system; };
            in
            lib.mapAttrs (_: v: v.variant.get.build) (mkWorld module-list ([ withSystem ] ++ modules))
          );
    };

    # Shortcuts without "namespace":
    inherit (n9.packages)
      patches
      patch
      assureVersion
      ;
    inherit (n9.options)
      mkOptionsFromConfig
      mkAttrsOfSubmoduleOption
      mkAttrsOfSubmoduleWithOption
      ;
    inherit (n9.modules)
      mkHosts
      mkEnvs
      ;
  };
in
n9
