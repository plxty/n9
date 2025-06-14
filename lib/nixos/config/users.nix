{ inputs, ... }:

{
  # @see https://nixos-and-flakes.thiscute.world/other-usage-of-flakes/module-system
  imports = [ inputs.home-manager.nixosModules.default ];
}
