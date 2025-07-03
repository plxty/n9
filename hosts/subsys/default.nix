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
      system.defaults.CustomUserPreferences =
        let
          # BUG: https://community.brave.com/t/bug-report-brave-on-macos-ignores-braveaichatenabled-and-bravewalletdisabled-group-policy-rules/625130
          # Policy group is broken for some values. When these options work, the brave://flags may be wiped.
          brave = {
            BraveAIChatEnabled = false;
            BraveWalletDisabled = true;
            BraveSyncUrl = "https://brave-sync.pteno.cn/";

            # https://superuser.com/a/1896063
            UpdateCheckEnabled = false;
            SUAutomaticallyUpdate = false;
          };
        in
        {
          "com.brave.Browser" = brave;
          "com.brave.Browser.nightly" = brave;
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
            # TODO: home.programs.thunderbird.nativeHost..?
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
              # https://github.com/brave/brave-core/pull/28463
              # You need to set the sync-url yourself now, the flags seems can't be managed by nix.
              # brave://flags #brave-override-sync-server-url
              (brave.overrideAttrs (
                prev:
                if lib.versionOlder prev.version "1.82.44" then
                  {
                    version = "1.82.44";
                    src = fetchurl {
                      url = "https://github.com/brave/brave-browser/releases/download/v1.82.44/brave-v1.82.44-darwin-arm64.zip";
                      hash = "sha256-ym4fS9W+2ZvtlcRy9Lo7fcCDaZTDSi/uXdTUcJh9tmE=";
                    };
                    installPhase = lib.replaceStrings [ "Brave Browser" ] [ "Brave Browser Nightly" ] prev.installPhase;
                  }
                else
                  { }
              ))

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
