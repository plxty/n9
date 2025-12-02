# Library of N9, devices should rely on this for modular.
# TODO: Mo(re)dules, when more devices.

{
  outputs =
    { nixpkgs, ... }@inputs:
    let
      inherit (nixpkgs) lib;
      n9 = import ./lib { inherit lib inputs; };
      module-list = import ./modules/module-list.nix;
    in
    {
      colmenaHive = n9.mkHosts module-list (import ./config/hosts-list.nix);
      devShells = n9.mkEnvs module-list (import ./config/envs-list.nix);

      # Export for sub-flakes:
      inherit (n9) mkHosts mkEnvs;
    };

  inputs = {
    # Stick to 25.11 for a while... Rolling is hurting my walts :(
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";

    colmena = {
      url = "github:zhaofengli/colmena";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        stable.follows = "";
        nix-github-actions.follows = "";
        flake-compat.follows = "";
      };
    };

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    pyproject-nix = {
      url = "github:pyproject-nix/pyproject.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixos-wsl = {
      url = "github:nix-community/NixOS-WSL";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-darwin = {
      url = "github:nix-darwin/nix-darwin/nix-darwin-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  nixConfig = {
    substituters = [
      "https://mirrors.sjtug.sjtu.edu.cn/nix-channels/store/"
      "https://mirrors.ustc.edu.cn/nix-channels/store/"
      "https://cache.nixos.org/"
    ];
  };
}
