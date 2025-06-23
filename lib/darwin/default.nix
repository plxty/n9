{
  lib,
  inputs,
  ...
}@args:

whereHosts:

(lib.evalModules {
  modules = [
    ../shared/config/os.nix
    {
      n9.map =
        { specialArgs, modules, ... }:
        {
          ${specialArgs.hostName} = inputs.nix-darwin.lib.darwinSystem {
            # @see https://github.com/NixOS/nixpkgs/blob/b367269ff3a9a6747a1e63b05be1c297364ba5bc/nixos/lib/eval-config-minimal.nix#L18
            specialArgs = args // specialArgs // { this = "darwin"; };

            modules = [
              ../home/config/users.nix
              ../shared/config/essentials.nix
              ./config/essentials.nix
            ] ++ modules;
          };
        };
    }
  ] ++ whereHosts;
}).config.n9.os
