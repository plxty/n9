{
  lib,
  n9,
  inputs,
  ...
}:

{
  # To provide pkgs in modules argument:
  imports = [ "${inputs.nixpkgs}/nixos/modules/misc/nixpkgs.nix" ];

  options.users = n9.mkAttrsOfSubmoduleOption { } {
    config.deployment.file.".config/nixpkgs/config.nix".text = ''
      { allowUnfree = true; }
    '';
  };

  # OSes will use the overrided `pkgs` with those options set:
  config.nixpkgs = {
    # https://wiki.nixos.org/wiki/Overlays
    # It's generally not a good idea to place packages here, which may cause
    # rebuild for package who relies one of the package here as dependency...
    # Therefore, try keep the overlay as minimal as possible, @see packages.nix
    # Here for mainly new apps, or something that downstream host config uses.
    overlays = [
      (final: prev: {
        # New toys:
        libkdumpfile = n9.mkPackage prev "libkdumpfile";
        drgn = n9.mkPackage prev "drgn";
        virtme-ng = n9.mkPackage prev "virtme-ng";
        rime-ice = n9.mkPackage prev "rime-ice";
        proot-rs = n9.mkPackage prev "proot-rs";
        nix-pack-closure = n9.mkPackage prev "nix-pack-closure";

        # Make fcitx5-rime or ibus-engines.rime works.
        # Overridding fcitx5 isn't simple as nixos uses `fcitx5-with-addons`.
        librime = n9.patch prev.librime "librime-temp-ascii";

        # Enforce the LUA version of librime-lua, same reason above:
        # @see pkgs/by-name/li/librime-lua/package.nix
        librime-lua = prev.librime-lua.overrideAttrs (prev': {
          propagatedBuildInputs = (lib.remove prev.lua prev'.propagatedBuildInputs) ++ [
            prev.lua5_4
          ];
        });

        # For private darwin machine (working only):
        iterm2 =
          let
            src = n9.sources.iterm2;
            version = lib.replaceStrings [ "_" ] [ "." ] src.version;
          in
          n9.assureVersion prev.iterm2 version {
            inherit src;
            nativeBuildInputs = [ prev.unzip ];
            unpackPhase = "unzip $src";
            sourceRoot = "iTerm.app"; # avoid /Applications/iTerm2.app/iTerm.app appears
          };

        flashspace =
          let
            src = n9.sources.flashspace;
          in
          n9.assureVersion prev.flashspace src.version {
            inherit src;
            nativeBuildInputs = [ prev.unzip ];
            unpackPhase = "unzip $src";
            sourceRoot = "flashspace.app";
          };

        # To skip some test fails... FIXME: Remove me when done!
        python313 =
          let
            packageOverrides =
              pyton-final: python-prev:
              let
                skipCheck =
                  pkg:
                  python-prev.${pkg}.overrideAttrs {
                    doInstallCheck = false;
                    doCheck = false;
                  };
                skipCheckIf = cond: pkgs: lib.genAttrs pkgs (if cond then skipCheck else n: python-prev.${n});
              in
              skipCheckIf (prev.stdenv.system == "aarch64-darwin") [
                "setproctitle" # keep failing...
                "pytest-benchmark" # test runs forever...
                "python-lsp-server" # keep failing...
              ];
          in
          prev.python313.override { inherit packageOverrides; };
      })
    ];

    # Unfree is acceptable, what's the price?
    config.allowUnfree = true;
  };
}
