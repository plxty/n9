{
  config,
  lib,
  n9,
  ...
}:

let
  cfg = config.n9.essentials.shared;
in
{
  options.n9.essentials.shared.enable = lib.mkOption {
    type = lib.types.bool;
    default = true;
  };

  config = lib.mkIf cfg.enable {
    nix.settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      inherit ((import ../../../flake.nix).nixConfig) substituters;
    };

    nix.extraOptions = ''
      keep-outputs = true
      keep-derivations = true
    '';

    nix.registry = {
      # nix develop n9#qemu
      n9.to = {
        type = "path";
        path = n9.dir; # save some debug times
      };
    };

    # https://nixos.wiki/wiki/Storage_optimization
    nix.gc = {
      automatic = true;
      options = "--delete-older-than 29d";
    };

    nixpkgs.config.allowUnfree = true;
  };
}
