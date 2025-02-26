{
  inputs.n9.url = "../..";

  outputs =
    { self, n9, ... }:
    {
      # TODO: homeConfigurations.byte = n9.lib.home self "byte" "x86_64-linux" [ ... ];
      nixosConfigurations.evil = n9.lib.nixos self "evil" "x86_64-linux" [
        ./hardware-configuration.nix
        {
          hardware.disk."disk/by-id/nvme-eui.002538b231b633a2".type = "zfs";
          miscell.sshd.enable = true;
        }
        {
          # home.byte.modules = [
          #   (
          #     { pkgs, ... }:
          #     {
          #       home.packages = with pkgs; [
          #         git-repo
          #         jetbrains.clion
          #       ];
          #     }
          #   )
          #   {
          #     login.passwd.file = "${secret}/passwd";
          #     desktop.pop-shell.enable = true;
          #     v12n.boxes.enable = true;

          #     miscell.git.enable = true;
          #     programs.git.includes = [
          #       {
          #         path = "~/.config/git/work"; # TODO: config.xdg.configHome?
          #         condition = "hasconfig:remote.*.url:*://*-inc.com*/**";
          #       }
          #     ];

          #     miscell.ssh = {
          #       ed25519.private = "${secret}/id_ed25519";
          #       ed25519.public = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICw9akIf3We4wbAwVfaqr8ANZYHLbtQ5sQGz1W5ZUE8Y byte@evil";
          #     };
          #     programs.ssh.includes = [ "config.d/*" ];

          #     secrets =
          #       (n9.lib.utils.secret "${secret}/ssh" ".ssh/config.d/hosts")
          #       // (n9.lib.utils.secret "${secret}/git" ".config/git/work");
          #   }
          # ];
        }
      ];
    };
}
