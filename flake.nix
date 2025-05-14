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
              ./hosts/iris
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
        }
        // (lib.mapAttrs (_: cfg: cfg.drv)
          (lib.evalModules {
            modules = [
              ./lib/shell
              ./shell/asterinas.nix
              ./shell/linux.nix
            ];
            specialArgs = args;
          }).config.n9.shell
        );
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
    # Stick to a version for a little while, don't be so aggrassive as it rebuilds a lot :/
    # @see https://github.com/NixOS/nixpkgs/commits/master/pkgs/development/libraries/webkitgtk/default.nix
    # @see pkgs/overlay.nix: webkitgtk
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    snapshot.url = "github:NixOS/nixpkgs/6c57ac8b3090d7022bd5ac1a072f297bdbdd6311";

    colmena = {
      url = "github:zhaofengli/colmena";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        stable.follows = "";
        nix-github-actions.follows = "";
        flake-compat.follows = "";
      };
    };

    nixos-anywhere = {
      url = "github:nix-community/nixos-anywhere";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        disko.follows = "";
        nixos-stable.follows = "";
        nixos-images.follows = "";
        treefmt-nix.follows = "";
      };
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
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-compat.follows = "";
      };
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
