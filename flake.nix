# Library of N9, devices should rely on this for modular.
# TODO: Mo(re)dules, when more devices.

{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    colmena = {
      url = "github:zhaofengli/colmena";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-anywhere = {
      url = "github:nix-community/nixos-anywhere";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { nixpkgs, colmena, ... }@inputs:
    let
      inherit (nixpkgs) lib;

      listDirectories =
        dir:
        let
          contents = builtins.readDir dir;
          directories = builtins.filter ({ value, ... }: value == "directory") (lib.attrsToList contents);
        in
        lib.map ({ name, ... }: name) directories;

      colmenaHive = colmena.lib.makeHive (
        lib.fold lib.recursiveUpdate {
          # @see lib/nixos.nix
          meta.nixpkgs = nixpkgs.legacyPackages.x86_64-linux; # will be overridden
          meta.specialArgs = lib.removeAttrs inputs [ "nixpkgs" ];
        } (lib.map (mach: import ./mach/${mach} inputs) [ "evil" ])
      );

      # @see nix/flake.nix
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
    in
    {
      lib = import ./lib/lib.nix inputs;
      inherit colmenaHive;
      nixosConfigurations = colmenaHive.nodes; # compatible
      devShell = nixpkgs.lib.genAttrs systems (import ./lib/shell.nix inputs);
    };

  nixConfig = {
    substituters = [
      "https://mirror.sjtu.edu.cn/nix-channels/store"
      "https://mirrors.ustc.edu.cn/nix-channels/store"
      "https://mirrors.sustech.edu.cn/nix-channels/store"
    ];
  };
}
