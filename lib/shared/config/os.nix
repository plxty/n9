{
  options,
  config,
  lib,
  ...
}:

let
  opt = options.n9;
  cfg = config.n9;

  map' =
    hostName: modules:
    let
      # Fetch nixpkgs.hostPlatform for system, it's a fake import as well:
      hwModule = ../../../hosts/${hostName}/hardware-configuration.nix;
      system =
        (import hwModule {
          config.hardware.enableRedistributableFirmware = null;
          inherit lib;
          pkgs = null;
          modulesPath = "";
        }).nixpkgs.hostPlatform.content;

      system' = lib.trace "n9: selecting ${system} for ${hostName}" system;
      specialArgs = {
        inherit hostName;
        userName = null; # make some "generic" modules working
        osOptions = opt.os.${hostName};
        osConfig = cfg.os.${hostName};

        # Try to avoid putting pkgs into specialArgs, which will cause a warning,
        # altough it's harmless :)
        # Possible values are "nixos", "darwin" and "home". TODO: Enum like?
        # To confirm, 'rg "this =="'
        # We want to make nix fail if "this" is undefined:
        # this = null;
      };
    in
    cfg.map {
      system = system';
      inherit specialArgs;
      modules = [
        modules
        hwModule
      ];
    };

  reduce = list: lib.fold lib.recursiveUpdate { } (lib.flatten list);

  final = attrs: cfg.final attrs;
in
{
  options.n9.map = lib.mkOption {
    type = lib.types.functionTo lib.types.unspecified;
  };

  options.n9.final = lib.mkOption {
    type = lib.types.functionTo lib.types.unspecified;
    default = lib.id;
  };

  # funny: n9.os.evil.n9.users.byte.n9.security.keys
  options.n9.os = lib.mkOption {
    type = lib.types.unspecified;
    apply =
      hosts:
      let
        list = lib.mapAttrsToList map' hosts;
        attrs = reduce list;
      in
      final attrs;
  };
}
