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
    chinese-fonts = {
      url = "github:brsvh/chinese-fonts-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      colmena,
      ...
    }@inputs:
    let
      inherit (nixpkgs) lib;

      mkSystems = import ./lib/nixos.nix inputs;
      colmenaHive = colmena.lib.makeHive (
        # @see lib/nixos.nix, meta.nixpkgs will be overridden:
        lib.fold lib.recursiveUpdate { meta.nixpkgs = nixpkgs.legacyPackages.x86_64-linux; } (
          self.lib.flatMap mkSystems [
            ./hosts/evil
            ./hosts/wa
            ./hosts/coffee
            ./hosts/harm
          ]
        )
      );

      mkShells =
        system:
        let
          args = inputs // {
            inherit system;
          };
        in
        {
          default = import ./shell/burn.nix args;
          qemu = import ./shell/qemu.nix args;
        };
    in
    {
      lib = import ./lib/lib.nix inputs;

      inherit colmenaHive;
      nixosConfigurations = colmenaHive.nodes; # compatible

      # @see nix/flake.nix
      devShells = nixpkgs.lib.genAttrs [
        "x86_64-linux"
        "aarch64-linux"
      ] mkShells;
    };

  nixConfig = {
    substituters = [
      "https://mirrors.ustc.edu.cn/nix-channels/store"
      "https://mirrors.sustech.edu.cn/nix-channels/store"
      # "https://mirror.sjtu.edu.cn/nix-channels/store"
    ];
  };
}
