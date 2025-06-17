{
  n9.os.subsys.imports = [
    {
      n9.users.byte.imports = [
        (
          { pkgs, ... }:
          {
            home.packages = with pkgs; [
              # FIXME: https://github.com/brave/brave-browser/issues/43181
              # system.defaults.CustomUserPreferences = { BraveSyncUrl = ... }
              # Downside: launchpad will not show, passkey is broken as well, but for working, it's okay now.
              (brave.overrideAttrs (prev: {
                postInstall = ''
                  cd "$out/Applications/Brave Browser.app/Contents/MacOS"
                  wrapProgram "$PWD/Brave Browser" --add-flag "--sync-url=https://brave-sync.pteno.cn/v2"
                '';
              }))

              vscode
              qemu

              # https://github.com/nix-darwin/nix-darwin/issues/1182#issuecomment-2963620315
              docker
              colima
            ];

            # use "colima template" for all options:
            home.file.".colima/default/colima.yaml".source = pkgs.writers.writeYAML "colima.yaml" {
              # virt-hardware
              vmType = "qemu";
              cpuType = "host";
              arch = "host";
              cpu = 2;
              disk = 100;
              memory = 2;

              # runtime
              runtime = "docker";
              hostname = "subsys";
              mountType = "sshfs";

              # misc
              kubernetes.enabled = false;
              autoActivate = true;
              sshConfig = false;

              mounts = [
                {
                  location = "/Volumes/Ice";
                  writable = true;
                }
              ];
            };
          }
        )
      ];
    }
  ];
}
