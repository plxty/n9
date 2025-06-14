{
  n9.os.subsys.imports = [
    {
      n9.users.byte.imports = [
        (
          { pkgs, ... }:
          {
            home.packages = with pkgs; [
              qemu
            ];
          }
        )
      ];
    }
  ];
}
