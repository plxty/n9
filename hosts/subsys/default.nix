{
  n9.os.subsys.imports = [
    (
      { pkgs, ... }:
      {
        # TODO: Merge with @see lib/nixos/config/gnome.nix
        # Nerd fonts can be installed by iterm2.
        fonts.packages = with pkgs; [
          jetbrains-mono
          source-code-pro
        ];
      }
    )

    {
      system.defaults.CustomUserPreferences = {
        "com.brave.Browser" = {
          BraveSyncUrl = "https://brave-sync.pteno.cn/v2";
        };
      };

      system.defaults.CustomSystemPreferences = {
        # https://github.com/runjuu/InputSourcePro/issues/24#issuecomment-2978745464
        "/Library/Preferences/FeatureFlags/Domain/UIKit.plist" = {
          redesigned_text_cursor.Enabled = false;
        };
      };
    }

    {
      n9.users.byte.imports = [
        (
          { pkgs, ... }:
          {
            home.packages = with pkgs; [
              # FIXME: https://github.com/brave/brave-browser/issues/43181
              # Downside: launchpad will not show, passkey is broken as well, but for working, it's okay now.
              (brave.overrideAttrs (prev: {
                postInstall = ''
                  cd "$out/Applications/Brave Browser.app/Contents/MacOS"
                  wrapProgram "$PWD/Brave Browser" --add-flag "--sync-url=https://brave-sync.pteno.cn/v2"
                '';
              }))

              vscode
              qemu
              # iterm2
              mos
            ];

            home.file."Library/Rime" = {
              source = "${pkgs.rime-ice}/share/rime-data";
              recursive = true;
              force = true;
            };
          }
        )

        {
          programs.fish.shellAliases.ve = "orb -m vexas exec fish";

          # n9.security.keys.".ssh/config.d/hosts".source = "ssh";
          programs.ssh = {
            # ssh kerberos, run kinit then ssh:
            extraConfig = ''
              GSSAPIAuthentication yes
              GSSAPIDelegateCredentials no
              HostKeyAlgorithms +ssh-rsa
              PubkeyAcceptedKeyTypes +ssh-rsa
            '';
          };
        }
      ];
    }
  ];
}
