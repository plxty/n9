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

    nixos-wsl = {
      url = "github:nix-community/NixOS-WSL";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-darwin = {
      url = "github:nix-darwin/nix-darwin/nix-darwin-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixos-x1e = {
      url = "github:plxty/nixos-x1e";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  nixConfig = {
    # @see https://github.com/NixOS/nix/commit/f8abbdd4565542464f31f4dc203a9c3e091b3536
    # @see https://github.com/NixOS/nix/commit/4029f4b05bfffcf6c5cbbfae1bfb9416c070b81e
    # Lower value means higher priority.
    substituters = [
      "https://mirrors.sjtug.sjtu.edu.cn/nix-channels/store/?priority=10"
      "https://mirrors.ustc.edu.cn/nix-channels/store/?priority=11"
      "https://cache.nixos.org/" # default
    ];
  };
}
