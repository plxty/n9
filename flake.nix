# Library of N9, devices should rely on this for modular.
# TODO: Mo(re)dules, when more devices.

{
  outputs =
    { nixpkgs, ... }@inputs:
    let
      # Unify the arguments, keep only libraries and inputs:
      inherit (nixpkgs) lib;
      n9 = import ./lib/lib.nix args;
      args = { inherit lib n9 inputs; };

      # NixOS
      nixosConfigurations = n9.hives "nixos" [
        ./hosts/iris
        ./hosts/evil
        ./hosts/wyvern
        ./hosts/dragon
        ./hosts/vexas
      ];

      # Nix Darwin
      darwinConfigurations = n9.hives "darwin" [
        ./hosts/subsys
      ];

      # To make us colmena, this is kind of copy paste :) TODO: To other config...
      # https://github.com/zhaofengli/colmena/blob/3ceec72cfb396a8a8de5fe96a9d75a9ce88cc18e/src/nix/hive/eval.nix#L184
      # Some features are missing, e.g. eval, they can be easily replaced by other commands.
      colmenaHive =
        let
          elem = builtins.elem;
          metaConfigKeys = [
            "name"
            "description"
            "machinesFile"
            "allowApplyAll"
          ];
        in
        rec {
          __schema = "v0.5";
          nodes = nixosConfigurations // darwinConfigurations;
          toplevel = lib.mapAttrs (_: v: v.config.system.build.toplevel) nodes;
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

      # Develop shells:
      shellConfigurations = n9.hells nixpkgs [
        ./shells/burn.nix
        ./shells/resume.nix
        ./shells/asterinas.nix
        ./shells/linux
        ./shells/bpf.nix
        ./shells/bpfd.nix
        ./shells/squirrel.nix
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
