{ pkgs, self, ... }:

{
  nixpkgs.overlays = [
    (_: super: {
      helix = self.lib.patch super.helix ../patches/helix-taste.patch;
      openssh = self.lib.patch super.openssh ../patches/openssh-plainpass.patch;
      ibus-engines = super.ibus-engines // {
        rime = (self.lib.patch super.ibus-engines.rime ../patches/ibus-rime-temp-ascii.patch).override {
          rimeDataPkgs = [ (pkgs.callPackage ../pkgs/rime-ice.nix { }) ];
        };
      };
      librime = self.lib.patch super.librime ../patches/librime-temp-ascii.patch;
      ppp = self.lib.patch super.ppp ../patches/ppp-run-resolv.patch;

      brave = super.brave.override (prev: {
        commandLineArgs = builtins.concatStringsSep " " [
          (prev.commandLineArgs or "")
          "--wayland-text-input-version=3"
          "--sync-url=https://brave-sync.pteno.cn/v2"
        ];
      });

      wechat = pkgs.callPackage ../pkgs/wechat.nix { };
      linux_wsl2 = pkgs.linuxPackagesFor (pkgs.callPackage ../pkgs/linux-kernel-wsl2.nix { });
    })
  ];

  nixpkgs.config.allowUnfree = true;
}
