{
  n9.os.coffee.imports = [
    {
      n9.hardware.disk.nvme0n1.type = "btrfs";
      deployment.allowLocalDeployment = true;

      n9.users.byte.imports = [
        (
          { pkgs, self, ... }:
          {
            home.packages = with pkgs; [
              wechat
              wpsoffice-cn
              # WARNING: Copyright! And extermely slow to download! It will
              # fetch the whole Windows ISO to extract the fonts.
              # TODO: Make a option of wps office?
              self.inputs.chinese-fonts.packages.${pkgs.system}.windows-fonts
            ];

            # https://github.com/nix-community/home-manager/issues/605
            fonts.fontconfig.enable = true;
          }
        )
        {
          n9.environment.gnome = {
            enable = true;
            swapCtrlCaps = true;
          };
          n9.security.ssh-key = {
            private = "id_ed25519";
            public = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBESP6hsTtRCTRchPimo4JVKnhP3l7ydhz49R4CBUyU7 byte@coffee";
          };
        }
      ];
    }
  ];
}
