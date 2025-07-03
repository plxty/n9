{
  options,
  config,
  lib,
  n9,
  inputs,
  hostName,
  this,
  ...
}:

let
  # Notice, we're in toplevel, this is the only toplevel config that controls
  # home-manager, because we have too much combinations of it:
  # * nixos + home-manager
  # * darwin + home-manager
  # * home-manager (standalone, currently won't support)
  # Therefore we make the platform specific config here, TODO: is it good?
  cfg = config.n9.users;

  commonModules = [
    (
      { name, ... }:
      {
        config._module.args.userName = name;
      }
    )
    ../../shared/config/keys.nix
    ../../shared/config/ssh-key.nix
    ./essentials.nix
    ./fish.nix
    ./helix.nix
  ];

  nixosModules = [
    ./passwd.nix
    ./gnome
    ./boxes.nix
  ];

  darwinModules = [
  ];
in
{
  imports = [
    inputs.home-manager.${
      if this ? nixos then
        "nixosModules"
      else if this ? darwin then
        "darwinModules"
      else
        abort "no supported home-manager!"
    }.default
  ];

  options.home-manager.users = lib.mkOption {
    type = lib.types.attrsOf (
      lib.types.submoduleWith {
        specialArgs = {
          inherit
            n9
            inputs
            hostName
            ;
          # You'd better not to access "userName" in the if statement.
          # We have some cases of the "this" value:
          # * nixos/nix-darwin/home-manager standalone,
          # * home-manager as module,
          # Only access usercfg if !(this ? homeModule), i.e. you have users.
          this = this // {
            homeModule = abort "yonah";
          };
        };

        modules =
          commonModules
          ++ (
            if this ? nixos then
              nixosModules
            else if this ? darwin then
              darwinModules
            else
              abort "no supported modules in users!"
          );
      }
    );
  };

  # To have our own namespace :) And to avoid potential inifinite recursion :(
  options.n9.users = options.home-manager.users;

  config = lib.mkIf (cfg != { }) (
    lib.mkMerge [
      {
        # https://discourse.nixos.org/t/users-users-name-packages-vs-home-manager-packages/22240/2
        home-manager.useUserPackages = true;
        home-manager.useGlobalPkgs = true;

        # We can access the "raw" definition values within options.definitions,
        # thus avoiding to have all the default configurations (like doRename).
        home-manager.users = lib.mkAliasDefinitions options.n9.users;
      }

      (lib.optionalAttrs (this ? nixos) {
        users.groups = lib.mapAttrs (_: _: { }) cfg;
        users.users = lib.mapAttrs (userName: _: {
          isNormalUser = lib.mkDefault true;
          group = userName;
          extraGroups = [ "wheel" ];
        }) cfg;
      })

      (lib.optionalAttrs (this ? darwin) {
        assertions = [
          {
            assertion = (lib.length (lib.attrNames cfg)) == 1;
            message = "darwin currently cannot have multiple user defined!";
          }
        ];

        users.users = lib.mapAttrs (userName: _: {
          name = userName;
          home = "/Users/${userName}";
        }) cfg;

        system.primaryUser = lib.elemAt (lib.attrNames cfg) 0;
      })
    ]
  );
}
