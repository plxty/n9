{
  n9.os.subsys.imports = [
    {
      # TODO: home-manager?
      system.defaults.CustomUserPreferences = {
        "com.brave.Browser" = {
          # @see lib/nixos/config/gnome.nix
          BraveSyncUrl = "https://brave-sync.pteno.cn/v2";
        };
      };

      n9.users.byte.imports = [
        (
          { pkgs, ... }:
          {
            home.packages = with pkgs; [
              brave
              qemu
            ];
          }
        )
      ];
    }
  ];
}
