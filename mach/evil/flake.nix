{
  inputs.n9.url = "../../lib";

  outputs =
    { n9, ... }:
    {
      nixosConfigurations.evil = n9.lib.nixosSystem "evil" "x86_64-linux" [
        ./hardware-configuration.nix
        {
          n9.hardware.disk."disk/by-id/nvme-eui.002538b231b633a2".type = "zfs";
          n9.services.sshd.enable = true;
          n9.users.byte.modules = [
            (
              { pkgs, ... }:
              {
                home.packages = with pkgs; [
                  git-repo
                  jetbrains.clion
                ];
              }
            )
            {
              n9.security.passwd.file = "/home/byte/.n9/asterisk/evil/ssh";
              n9.environment.pop-shell.enable = true;
              n9.virtualisation.boxes.enable = true;

              n9.security.secrets.".config/git/work".source = "/home/byte/.n9/asterisk/evil/git";
              programs.git.includes = [
                {
                  path = "~/.config/git/work"; # TODO: config.xdg.configHome?
                  condition = "hasconfig:remote.*.url:*://*-inc.com*/**";
                }
              ];

              #     miscell.ssh = {
              #       ed25519.private = "${secret}/id_ed25519";
              #       ed25519.public = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICw9akIf3We4wbAwVfaqr8ANZYHLbtQ5sQGz1W5ZUE8Y byte@evil";
              #     };

              n9.security.secrets.".ssh/config.d/hosts".source = "/home/byte/.n9/asterisk/evil/ssh";
              programs.ssh.includes = [ "config.d/*" ];
            }
          ];
        }
      ];
    };
}
