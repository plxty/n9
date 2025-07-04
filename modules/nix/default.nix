{ n9, ... }@args:

{
  config = {
    nix.settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      inherit ((import ../../flake.nix).nixConfig) substituters;
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

    # TODO: The standalone home doesn't support it:
    nix.optimise.automatic = true;

    # Make overlay everywhere.
    nixpkgs.overlays = [ (import ../../pkgs/overlay.nix args) ];

    # Unfree is acceptable, what's the price?
    nixpkgs.config.allowUnfree = true;
  };
}
