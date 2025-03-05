{
  n9.os.nowhere.imports = [
    ./hardware-configuration.nix
    {
      n9.hardware.disk.vda.type = "btrfs";
      nix.settings.trusted-public-keys = [ "evil.xa-1:3N+fGCh9nVbctbwFhQad1qF2EqOp6FM83E08sBNGIlw=" ];
      deployment = {
        # ssh -R within vm
        targetHost = "127.0.0.1";
        targetPort = 2233;
        targetUser = "byte";
      };

      n9.users.byte.imports = [
        {
          # Just a test virtual machine under evil, for simplicity.
          n9.security.passwd.file = "evil/passwd";
          n9.security.ssh-key.agents = [ "byte@evil" ];
        }
      ];
    }
  ];
}
