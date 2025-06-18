# orbstack container, development
# TODO: Make a wine like wrapper?

{
  n9.os.vexas.imports = [
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
      n9.users.byte.imports = [
        {
          # coop with shell/linux and "make qemu":
          programs.fish.functions.share = ''
            set -f fish_trace 1
            macctl push $argv[1] /var/lib/images/share
          '';
        }
      ];
    }
  ];
}
