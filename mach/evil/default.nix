{
  n9.os.evil.imports = [
    {
      n9.hardware.disk."disk/by-id/nvme-eui.002538b231b633a2".type = "zfs";
      n9.services.sshd.enable = true;
      deployment.allowLocalDeployment = true;

      n9.users.byte.imports = [
        (
          { pkgs, ... }:
          {
            home.packages = with pkgs; [
              git-repo
              jetbrains.clion
              lmstudio
              zenity
              freerdp3
            ];
          }
        )
        {
          n9.environment.gnome.enable = true;
          n9.virtualisation.boxes.enable = true;

          n9.security.ssh-key = {
            private = "id_ed25519"; # n9/asterisk/evil/byte/id_ed25519
            public = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICw9akIf3We4wbAwVfaqr8ANZYHLbtQ5sQGz1W5ZUE8Y byte@evil";
          };

          n9.security.keys.".config/git/work".source = "git";
          programs.git.includes = [
            {
              path = "~/.config/git/work";
              condition = "hasconfig:remote.*.url:*://*-inc.com*/**";
            }
          ];

          n9.security.keys.".ssh/config.d/hosts".source = "ssh";
          programs.ssh.includes = [ "config.d/*" ];
        }
      ];
    }
  ];
}
