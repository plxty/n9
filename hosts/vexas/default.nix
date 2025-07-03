# orbstack container, development
# TODO: Make a wine like wrapper?

{
  n9.system.vexas.imports = [
    {
      nixpkgs.hostPlatform = "aarch64-linux";
    }

    (
      {
        config,
        pkgs,
        lib,
        modulesPath,
        ...
      }@args:
      let
        generated = import ./inherit/configuration.nix args;
      in
      {
        # We only need some of the configuration, to not pollute us much.
        inherit (generated)
          imports
          security
          networking
          systemd
          ;
        users.users.byte = lib.removeAttrs (
          generated.users.users.byte
          // {
            isNormalUser = false;
          }
        ) [ "group" ];

        # To live together:
        boot.loader.systemd-boot.enable = lib.mkForce false;
      }
    )

    {
      n9.users.byte = {
        # Hmm, nothing specials.
      };
    }
  ];
}
