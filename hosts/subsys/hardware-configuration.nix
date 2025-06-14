{ lib, ... }:

# Nothing but a dumb file, to indicate if is Apple Silicon.
# For nix-darwin, we won't update this file when burn.

{
  nixpkgs.hostPlatform = lib.mkDefault "aarch64-darwin";
}
