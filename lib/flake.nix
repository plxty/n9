# Library of N9, devices should rely on this for modular.
# TODO: Mo(re)dules, when more devices.

{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    colmena = {
      url = "github:zhaofengli/colmena";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-anywhere = {
      url = "github:nix-community/nixos-anywhere";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      colmena,
      ...
    }@args:
    let
      # @see nix/flake.nix
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
    in
    {
      # NixOS, Nix (For package manager only, use lib.mkNixPackager?):
      lib.nixos = import ./lib/nixos.nix args;
      lib.nixos-modules = import ./nixos args;

      # User/home level modules, with home-manager:
      lib.home = import ./lib/home.nix args;
      lib.home-modules = import ./home args;

      # Simple utils, mainly for making the code "shows" better.
      # In modules, you can refer it using `self.lib.utils`.
      lib.utils = import ./lib/utils.nix args;

      # Entry:
      devShell = nixpkgs.lib.genAttrs systems (import ./lib/shell.nix args);
    };

  nixConfig = {
    substituters = [
      "https://mirror.sjtu.edu.cn/nix-channels/store"
      "https://mirrors.ustc.edu.cn/nix-channels/store"
      "https://mirrors.sustech.edu.cn/nix-channels/store"
    ];
  };
}
