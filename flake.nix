# Library of N9, devices should rely on this for modular.
# TODO: Mo(re)dules, when more devices.

{
  outputs =
    {
      self,
      nixpkgs,
      colmena,
      ...
    }@allInputs:
    let
      inherit (nixpkgs) lib;

      # Unify the arguments, keep only n9 (outputs) and inputs:
      n9 = self.lib;
      inputs = {
        inherit n9;
        inputs = allInputs;
      };

      mkSystems = import ./lib/nixos.nix inputs;
      colmenaHive = colmena.lib.makeHive (
        # @see lib/nixos.nix, meta.nixpkgs will be overridden:
        lib.fold lib.recursiveUpdate
          {
            meta.nixpkgs.lib = lib;
            meta.specialArgs = inputs;
          }
          (
            n9.flatMap mkSystems [
              ./hosts/evil
              ./hosts/wa
              ./hosts/coffee
              ./hosts/dragon
            ]
          )
      );

      mkShells =
        system:
        let
          args = inputs // {
            pkgs = n9.mkPkgs system;
          };
        in
        {
          default = import ./shell/burn.nix args;
          tex = import ./shell/tex.nix args;
          qemu = import ./shell/qemu.nix args;
          linux = import ./shell/linux.nix args;
          asterinas = import ./shell/asterinas.nix args;
        };
    in
    {
      lib = import ./lib/lib.nix inputs;

      inherit colmenaHive;
      nixosConfigurations = colmenaHive.nodes; # compatible

      # @see nix/flake.nix
      devShells = lib.genAttrs [
        "x86_64-linux"
        "aarch64-linux"
      ] mkShells;
    };

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

    nixos-wsl = {
      url = "github:nix-community/NixOS-WSL";
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

    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  nixConfig = {
    substituters = [
      "https://mirrors.ustc.edu.cn/nix-channels/store"
      "https://mirrors.sustech.edu.cn/nix-channels/store"
      # "https://mirror.sjtu.edu.cn/nix-channels/store"
      "https://cache.nixos.org"
    ];
  };
}
