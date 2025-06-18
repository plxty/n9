{ lib, ... }:

# A dumb file as well, just the n9 needs it.
# For orbstack, the configuration predefined is used instead.

{
  nixpkgs.hostPlatform = lib.mkDefault "aarch64-linux";
}
