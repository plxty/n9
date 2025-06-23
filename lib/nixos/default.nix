{
  lib,
  n9,
  inputs,
  ...
}:

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
          meta.nodeNixpkgs.${specialArgs.hostName} = n9.mkNixpkgs inputs.nixpkgs system;
          meta.nodeSpecialArgs.${specialArgs.hostName} = specialArgs;

          ${specialArgs.hostName} = n9.recursiveMerge [
            {
              imports = [
                # nixos (linux) modules
                ./config/disk.nix
                ./config/network.nix
                ./config/sshd.nix
                ../generic/config/users.nix
                ./config/users.nix
                ../generic/config/keys.nix
                ./config/keys.nix
                ./config/passwd.nix
                ./config/ssh-key.nix
                ./config/gnome.nix
                ./config/boxes.nix

                # configs
                ../generic/essential.nix
                ./essential.nix
              ];
            }
            modules
          ];
        };

      n9.final = attrs: inputs.colmena.lib.makeHive attrs;
    }
  ] ++ whereHosts;
}).config.n9.os
