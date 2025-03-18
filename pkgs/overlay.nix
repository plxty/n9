{ n9, ... }:

final: prev: {
  helix = n9.patch prev.helix ./patches/helix-taste.patch;
  openssh = n9.patch prev.openssh ./patches/openssh-plainpass.patch;
  ibus-engines = prev.ibus-engines // {
    rime = (n9.patch prev.ibus-engines.rime ./patches/ibus-rime-temp-ascii.patch).override {
      rimeDataPkgs = [ (final.callPackage ./rime-ice.nix { }) ];
    };
  };
  librime = n9.patch prev.librime ./patches/librime-temp-ascii.patch;
  ppp = n9.patch prev.ppp ./patches/ppp-run-resolv.patch;

  brave = prev.brave.override (prev: {
    commandLineArgs = builtins.concatStringsSep " " [
      (prev.commandLineArgs or "")
      "--wayland-text-input-version=3"
      "--sync-url=https://brave-sync.pteno.cn/v2"
    ];
  });

  wechat = final.callPackage ./wechat.nix { };
}
