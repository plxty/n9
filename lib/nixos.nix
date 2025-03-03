{ nixpkgs, ... }: # <- Flake inputs

# Make NixOS, with disk, bootloader, networking, hostname, etc.
hostName: system: modules:

# For reverting to nixosSystem, commit 0dfc786daefb441c8e14b3f97fa3393847d1de9d
{
  meta.nodeNixpkgs.${hostName} = nixpkgs.legacyPackages.${system};
  meta.nodeSpecialArgs.${hostName} = { inherit hostName; };

  ${hostName} = {
    imports = [
      # options
      ./nixos/config/disk.nix
      ./nixos/config/sshd.nix
      ./nixos/config/users.nix
      ./nixos/config/secrets.nix
      ./nixos/config/passwd.nix
      ./nixos/config/pop-shell.nix
      ./nixos/config/boxes.nix

      # configs
      ./nixos/essential.nix
    ] ++ modules;
  };
}
