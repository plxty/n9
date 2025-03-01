{
  self,
  nixpkgs,
  ...
}@inputs: # <- Flake inputs

# Make NixOS, with disk, bootloader, networking, hostname, etc.
hostName: system: modules:

nixpkgs.lib.nixosSystem {
  inherit system;

  # ++ (lib.optionals (deployment ? nixKey) [
  #   # nix key generate-secret --key-name dotfiles.rockwolf.eu-X > .nix-key
  #   # cat .nix-key | nix key convert-secret-to-public
  #   { nix.settings.trusted-public-keys = [ deployment.nixKey ]; }
  # ])

  specialArgs.n9 = {
    inherit hostName inputs;
    inherit (self) lib;
  };

  # Seems like the `extraModules` and `modules` are the same, the only different
  # is the `extraModule` will get exported to `_module.args`.
  # They're sharing the same nixpkgs module system, placing all `options` here
  # is just a "conventional".
  extraModules = [
    ./nixos/config/disk.nix
    ./nixos/config/sshd.nix
    ./nixos/config/users.nix
    ./nixos/config/secrets.nix
    ./nixos/config/passwd.nix
    ./nixos/config/pop-shell.nix
    ./nixos/config/boxes.nix
  ];

  # Essential:
  modules = [ ./nixos/essential.nix ] ++ modules;
}
