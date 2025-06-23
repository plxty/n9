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
        }:
        {
          meta.nixpkgs.lib = lib;
          meta.specialArgs = args;

          meta.nodeNixpkgs.${specialArgs.hostName} = n9.mkNixpkgs inputs.nixpkgs system;
          meta.nodeSpecialArgs.${specialArgs.hostName} = specialArgs // {
            this = "nixos";
          };

          ${specialArgs.hostName} = {
            imports = [
              ./config/disk.nix
              ./config/network
              ./config/sshd.nix
              ../home/config/users.nix
              ../shared/config/keys.nix
              ./config/keys.nix
              ./config/passwd.nix
              ./config/ssh-key.nix
              ./config/gnome.nix
              ./config/boxes.nix
              ../shared/config/essentials.nix
              ./config/essentials.nix
            ] ++ modules;
          };
        };

      n9.final = attrs: inputs.colmena.lib.makeHive attrs;
    }
  ] ++ whereHosts;
}).config.n9.os
