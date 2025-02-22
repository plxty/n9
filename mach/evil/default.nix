{ self, n9, ... }:

let
  secret = "@ASTERISK@/evil";
in
{
  nixosConfigurations = n9.lib.nixos self "evil" "x86_64-linux" {
    modules = with n9.lib.nixos-modules; [
      ./hardware-configuration.nix
      (disk.zfs "/dev/disk/by-id/nvme-eui.002538b231b633a2")
      (miscell.sshd { })
    ];
  };

  homeConfigurations = n9.lib.home self "byte" "${secret}/passwd" {
    packages = [
      "git-repo"
      "jetbrains.clion"
    ];

    modules = with n9.lib.home-modules; [
      desktop.pop-shell
      v12n.boxes
      miscell.git
      {
        programs.git.includes = [
          {
            path = "~/.config/git/work"; # TODO: config.xdg.configHome?
            condition = "hasconfig:remote.*.url:*://*-inc.com*/**";
          }
        ];
      }
      (miscell.ssh {
        ed25519.private = "${secret}/id_ed25519";
        ed25519.public = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICw9akIf3We4wbAwVfaqr8ANZYHLbtQ5sQGz1W5ZUE8Y byte@evil";
      })
      { programs.ssh.includes = [ "config.d/*" ]; }
    ];

    secrets =
      (n9.lib.utils.secret "${secret}/ssh" ".ssh/config.d/hosts")
      // (n9.lib.utils.secret "${secret}/git" ".config/git/work");
  };
}
