{ pkgs, n9, ... }:

{
  nixpkgs.overlays = [
    (_: super: {
      helix = n9.patch super.helix ./patches/helix-taste.patch;
      openssh = n9.patch super.openssh ./patches/openssh-plainpass.patch;
      ibus-engines = super.ibus-engines // {
        rime = (n9.patch super.ibus-engines.rime ./patches/ibus-rime-temp-ascii.patch).override {
          rimeDataPkgs = [ (pkgs.callPackage ./rime-ice.nix { }) ];
        };
      };
      librime = n9.patch super.librime ./patches/librime-temp-ascii.patch;
      ppp = n9.patch super.ppp ./patches/ppp-run-resolv.patch;

      brave = super.brave.override (prev: {
        commandLineArgs = builtins.concatStringsSep " " [
          (prev.commandLineArgs or "")
          "--wayland-text-input-version=3"
          "--sync-url=https://brave-sync.pteno.cn/v2"
        ];
      });

      wechat = pkgs.callPackage ./wechat.nix { };
    })
  ];

  nixpkgs.config.allowUnfree = true;
}
