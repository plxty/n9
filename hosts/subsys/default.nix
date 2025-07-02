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
          { pkgs, config, ... }:
          let
            # https://github.com/Frederick888/external-editor-revived/wiki/macOS
            eer = rec {
              filename = "external_editor_revived.json";

              src = pkgs.fetchzip {
                url = "https://github.com/Frederick888/external-editor-revived/releases/download/v1.2.0/macos-latest-universal-native-messaging-host-v1.2.0.zip";
                nativeBuildInputs = with pkgs; [ darwin.xattr ];
                postFetch = ''
                  xattr -c "$out/external-editor-revived"
                  chmod +x "$out/external-editor-revived"
                '';
                hash = "sha256-Poje8oM7/qUMeOqBWYL5Kos/3/6iCSPSZo1oPHNQJuw=";
              };

              # The fetchzip is a fixed-output derivition, which means we can't reference other /nix.
              out = pkgs.runCommand filename { } ''
                mkdir -p $out
                cd $out
                ${src}/external-editor-revived > ${filename}
              '';
            };
          in
          {
            home.packages = with pkgs; [
              # FIXME: https://github.com/brave/brave-browser/issues/43181
              # Waiting for https://github.com/brave/brave-core/pull/28463 to be merged.
              # Downside: launchpad will not show, passkey is broken as well, acceptable :(
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
              thunderbird
            ];

            home.file."Library/Rime" = {
              source = "${pkgs.rime-ice}/share/rime-data";
              recursive = true;
              force = true;
            };

            home.file."Library/Mozilla/NativeMessagingHosts/${eer.filename}".source =
              "${eer.out}/${eer.filename}";

            programs.fish.shellAliases.ve = "orb -m vexas exec fish";

            # n9.security.keys.".ssh/config.d/hosts".source = "ssh";
            programs.ssh = {
              matchBlocks = {
                ve = {
                  hostname = "localhost";
                  port = 32222;
                  identityFile = "${config.home.homeDirectory}/.orbstack/ssh/id_ed25519";
                };
              };

              # ssh kerberos, run kinit then ssh:
              extraConfig = ''
                GSSAPIAuthentication yes
                GSSAPIDelegateCredentials no
                HostKeyAlgorithms +ssh-rsa
                PubkeyAcceptedKeyTypes +ssh-rsa
              '';
            };
          }
        )
      ];
    }
  ];
}
