{
  lib,
  n9,
  inputs,
  ...
}@args:

whereHosts:

(lib.evalModules {
  modules = [
    ../shared/config/os.nix
    {
      n9.map =
        {
          system,
          specialArgs,
          modules,
          ...
        }:
        {
          ${specialArgs.hostName} = inputs.nix-darwin.lib.darwinSystem {
            # Specify pkgs early to prevent from evalModules lookup config._module.args,
            # which will cause the infinite loop when evaluating.
            # @see https://github.com/NixOS/nixpkgs/blob/b367269ff3a9a6747a1e63b05be1c297364ba5bc/nixos/lib/eval-config-minimal.nix#L18
            specialArgs = { pkgs = n9.mkNixpkgs inputs.nixpkgs system; } // args // specialArgs;

            modules = [
              ../shared/config/essentials.nix
              ./config/essentials.nix
              ../home/config/users.nix
            ] ++ modules;
          };
        };
    }
  ] ++ whereHosts;
}).config.n9.os
