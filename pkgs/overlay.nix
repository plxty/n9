{ n9, inputs, ... }:

final: prev:
let
  snapshot = inputs.snapshot.legacyPackages.${final.system};
in
{
  helix = n9.patch prev.helix ./patches/helix-taste.patch;
  openssh = n9.patch prev.openssh ./patches/openssh-plainpass.patch;
  ibus-engines = prev.ibus-engines // {
    rime = (n9.patch prev.ibus-engines.rime ./patches/ibus-rime-temp-ascii.patch).override {
      rimeDataPkgs = [ (final.callPackage ./rime-ice.nix { }) ];
    };
  };
  librime = n9.patch prev.librime ./patches/librime-temp-ascii.patch;
  ppp = n9.patch prev.ppp ./patches/ppp-run-resolv.patch;
  gnomeExtensions = prev.gnomeExtensions // {
    paperwm = n9.patch prev.gnomeExtensions.paperwm ./patches/paperwm-focus.patch;
    customize-ibus = n9.patch prev.gnomeExtensions.customize-ibus ./patches/customize-ibus-keep.patch;
  };

  # FIXME: https://issues.chromium.org/issues/408167436 waiting for fixes, therefore snapshot:
  brave = snapshot.brave.override (prev: {
    commandLineArgs = builtins.concatStringsSep " " [
      (prev.commandLineArgs or "")
      "--wayland-text-input-version=3"
      "--sync-url=https://brave-sync.pteno.cn/v2"
    ];
  });

  wechat = final.callPackage ./wechat.nix { };

  # @see flake.nix, to prevent from long-time compiling, it might break the system :(
  inherit (snapshot)
    webkitgtk_6_0
    webkitgtk_4_0
    webkitgtk_4_1
    ;
}
