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
      inputs.disko.follows = "disko";
    };
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    paperwm = {
      url = "github:paperwm/PaperWM";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { nixpkgs, colmena, ... }@inputs:
    let
      inherit (nixpkgs) lib;

      # TODO: builtins.filterSource like?
      listDirectories =
        dir:
        let
          contents = builtins.readDir dir;
          directories = builtins.filter ({ value, ... }: value == "directory") (lib.attrsToList contents);
        in
        lib.map ({ name, ... }: "${dir}/${name}") directories;

      mkSystems = import ./lib/nixos.nix inputs;
      colmenaHive = colmena.lib.makeHive (
        lib.fold lib.recursiveUpdate {
          # @see lib/nixos.nix
          meta.nixpkgs = nixpkgs.legacyPackages.x86_64-linux; # will be overridden
          meta.specialArgs = lib.removeAttrs inputs [ "nixpkgs" ];
        } (lib.flatten (lib.map mkSystems (listDirectories ./mach)))
      );
    in
    {
      lib = import ./lib/lib.nix inputs;

      inherit colmenaHive;
      nixosConfigurations = colmenaHive.nodes; # compatible

      # @see nix/flake.nix
      devShell = nixpkgs.lib.genAttrs [
        "x86_64-linux"
        "aarch64-linux"
      ] (import ./shell/burn.nix inputs);
    };

  nixConfig = {
    substituters = [
      "https://mirrors.ustc.edu.cn/nix-channels/store"
      "https://mirrors.sustech.edu.cn/nix-channels/store"
      # "https://mirror.sjtu.edu.cn/nix-channels/store"
    ];
  };
}
