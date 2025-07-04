{
  pkgs,
  n9,
  ...
}:

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

    # https://github.com/luishfonseca/nixos-config/blob/main/modules/upgrade-diff.nix
    # https://github.com/nix-darwin/nix-darwin/blob/e04a388232d9a6ba56967ce5b53a8a6f713cdfcf/modules/system/activation-scripts.nix#L114
    system.activationScripts.postActivation = {
      # supportsDryActivation = true; # TODO: doesn't exist in darwin...
      text = ''
        ${pkgs.nvd}/bin/nvd --nix-bin-dir=${pkgs.nix}/bin diff /run/current-system "$systemConfig"
      '';
    };

    nixpkgs.config.allowUnfree = true;
  };
}
