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
      n9.users.byte = {
        # TODO: To subsys, when "keys" work:
        n9.security.keys.".config/git/work".source = "git";
        programs.git.includes = [
          {
            path = "~/.config/git/work";
            condition = "hasconfig:remote.*.url:git@code.byted.org:*/**";
          }
        ];
      };
    }
  ];
}
