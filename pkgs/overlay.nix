{ n9, ... }:

final: prev: {
  # New packages:
  wechat = final.callPackage ./wechat.nix { };
  rime-ice = final.callPackage ./rime-ice.nix { };

  # System hack:
  openssh = n9.patch prev.openssh "openssh-plainpass";
  ibus-engines = prev.ibus-engines // {
    rime = (n9.patch prev.ibus-engines.rime "ibus-rime-temp-ascii").override {
      rimeDataPkgs = [ final.rime-ice ];
    };
  };
  librime = n9.patch prev.librime "librime-temp-ascii";
}
