# Library of N9, devices should rely on this for modular.
# TODO: Mo(re)dules, when more devices.

{
  outputs =
    { nixpkgs, ... }@inputs:
    let
      # Unify the arguments, keep only libraries and inputs:
      inherit (nixpkgs) lib;
      n9 = import ./nix/lib.nix args;
      args = { inherit lib n9 inputs; };

      # NixOS:
      nixosConfigurations = n9.systems "nixos" [
        ./config/hosts/iris
        ./config/hosts/evil
        ./config/hosts/wyvern
        ./config/hosts/vexas
      ];

      # Nix Darwin:
      darwinConfigurations = n9.systems "darwin" [
        ./config/hosts/subsys
      ];

      # Burn apply:
      colmenaHive = n9.hives (nixosConfigurations // darwinConfigurations);

      # Develop shells:
      shellConfigurations = n9.hells nixpkgs [
        ./config/shells/burn.nix
        ./config/shells/resume.nix
        ./config/shells/asterinas.nix
        ./config/shells/linux
        ./config/shells/bpf.nix
        ./config/shells/bpfd.nix
        ./config/shells/squirrel.nix
      ];
    in
    {
      # compatible:
      inherit
        nixosConfigurations
        darwinConfigurations
        colmenaHive
        ;

      # @see nix/flake.nix
      devShells = lib.genAttrs [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
      ] shellConfigurations;
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

    nixos-wsl = {
      url = "github:nix-community/NixOS-WSL";
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
