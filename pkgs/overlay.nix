{ lib, n9, ... }:

final: prev: {
  rime-ice = final.callPackage ./rime-ice.nix { inherit n9; };

  # FIXME: WIP
  crash = final.callPackage ./crash.nix { };

  # The home-manager doesn't have an option to customize openssh, thus we make
  # it global. TODO: submit patches to community?
  # openssh = prev.opensshWithKerberos; will cause inifinite recursion, why?
  openssh = prev.openssh.override {
    withKerberos = lib.trace "overlay derivition created" true;
  };

  ibus-engines = prev.ibus-engines // {
    rime = (n9.patch prev.ibus-engines.rime "ibus-rime-temp-ascii").override {
      rimeDataPkgs = [ final.rime-ice ];
    };
  };

  librime = n9.patch prev.librime "librime-temp-ascii";
}
