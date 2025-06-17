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
            ];

            # ssh kerberos, run kinit then ssh:
            programs.ssh.extraConfig = ''
              GSSAPIAuthentication yes
              GSSAPIDelegateCredentials no
              HostKeyAlgorithms +ssh-rsa
              PubkeyAcceptedKeyTypes +ssh-rsa
            '';
          }
        )
      ];
    }
  ];
}
