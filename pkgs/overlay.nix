{ n9, ... }:

final: prev: {
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
}
