# Library of N9, devices should rely on this for modular.
# TODO: Mo(re)dules, when more devices.

{
  outputs =
    {
      nixpkgs,
      colmena,
      nix-darwin,
      ...
    }@inputs:
    let
      # Unify the arguments, keep only libraries and inputs:
      inherit (nixpkgs) lib;
      n9 = import ./lib/lib.nix args;
      args = { inherit lib n9 inputs; };

      # Helpers:
      oses =
        type: initial: list:
        lib.fold lib.recursiveUpdate initial (
          n9.flatMap (
            if type == "linux" then
              import ./lib/nixos args
            else if type == "darwin" then
              import ./lib/darwin args
            else
              abort "unsupported os?"
          ) list
        );

      # Systems:
      colmenaHive = colmena.lib.makeHive (
        # @see lib/nixos/default.nix, meta.nixpkgs will be overridden:
        oses "linux"
          {
            meta.nixpkgs.lib = lib;
            meta.specialArgs = args;
          }
          [
            ./hosts/iris
            ./hosts/evil
            ./hosts/dragon
            ./hosts/vexas
          ]
      );

      # Non-colmena, nix-darwin now:
      darwinConfigurations = lib.mapAttrs (_: nix-darwin.lib.darwinSystem) (
        oses "darwin" { } [ ./hosts/subsys ]
      );

      # Develop shells:
      mkShells =
        system:
        ((import ./lib/shell (args // { pkgs = n9.mkPkgs system; })) [
          ./shells/burn.nix
          ./shells/resume.nix
          ./shells/asterinas.nix
          ./shells/linux.nix
          ./shells/bpf.nix
        ]);
    in
    {
      inherit colmenaHive darwinConfigurations;
      nixosConfigurations = colmenaHive.nodes; # compatible

      # @see nix/flake.nix
      devShells = lib.genAttrs [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
      ] mkShells;
    };

  inputs = {
    # Stick to 25.05 for a while... Rolling is hurting my walts :(
    # Relavant changes if version bumped:
    # * home-manager
    # * nix-channel (burn)
    # * nix-darwin
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";

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
        nix-vm-test.follows = "";
      };
    };

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager/release-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixos-x1e = {
      url = "github:plxty/nixos-x1e";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-darwin = {
      url = "github:nix-darwin/nix-darwin/nix-darwin-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  nixConfig = {
    substituters = [
      "https://mirror.sjtu.edu.cn/nix-channels/store"
      "https://mirrors.ustc.edu.cn/nix-channels/store"
      "https://mirrors.sustech.edu.cn/nix-channels/store"
      "https://cache.nixos.org"
    ];
  };
}
