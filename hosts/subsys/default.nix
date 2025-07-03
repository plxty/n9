{
  n9.system.subsys.imports = [
    {
      nixpkgs.hostPlatform = "aarch64-darwin";

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
    }

    {
      n9.users.byte.imports = [
        (
          {
            pkgs,
            config,
            n9,
            ...
          }:
          let
            # https://github.com/Frederick888/external-editor-revived/wiki/macOS
            # TODO: home.programs.thunderbird.nativeHost..?
            eer = rec {
              filename = "external_editor_revived.json";
              src = n9.sources.external-editor-revived;
              out =
                pkgs.runCommand "external-editor-revived"
                  {
                    # Niv doesn't support fetchzip, sadly...
                    nativeBuildInputs = with pkgs; [ unzip ];
                  }
                  ''
                    mkdir -p $out
                    cd $out
                    unzip "${src}"
                    ./external-editor-revived > ${filename}
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

            programs.ssh.matchBlocks.ve = {
              hostname = "localhost";
              port = 32222;
              identityFile = "${config.home.homeDirectory}/.orbstack/ssh/id_ed25519";
            };
            programs.fish.shellAliases.ve = "orb -m vexas exec fish";

            n9.security.ssh-key = {
              private = "id_ed25519";
              public = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHseVadGEcUcnDZ7+M8oQeuvEZrbMeEj3PWk/o8LIygX byte@subsys";
            };
          }
        )
      ];
    }
  ];
}
