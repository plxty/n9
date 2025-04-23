{ n9, inputs, ... }:

final: prev:
let
  snapshot = inputs.snapshot.legacyPackages.${final.system};
in
{
  # System hack:
  openssh = n9.patch prev.openssh "openssh-plainpass";
  ibus-engines = prev.ibus-engines // {
    rime = (n9.patch prev.ibus-engines.rime "ibus-rime-temp-ascii").override {
      rimeDataPkgs = [ (final.callPackage ./rime-ice.nix { }) ];
    };
  };
  librime = n9.patch prev.librime "librime-temp-ascii";

  # New packages:
  wechat = final.callPackage ./wechat.nix { };

  inherit (snapshot)
    # FIXME: https://issues.chromium.org/issues/408167436 waiting for fixes, therefore snapshot:
    brave
    # @see flake.nix, to prevent from long-time compiling, it might break the system :(
    webkitgtk_6_0
    webkitgtk_4_0
    webkitgtk_4_1
    ;
}
