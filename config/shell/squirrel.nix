# Squirrel may not package with the nixpkgs, as it's quite hard to build, and
# the xcode requires a lot interactive things to set-up.
# Therefore it's better to mantain the package my-self.
# Maybe oneday the package will be set, and everything will start going well :)
# https://github.com/NixOS/nixpkgs/blob/master/doc/stdenv/platform-notes.chapter.md

{
  n9.shell.squirrel =
    {
      lib,
      pkgs,
      inputs,
      ...
    }:
    let
      sdk = rec {
        version = "15";
        xcode = "16_3";
        path = "${pkgs.darwin."xcode_${xcode}"}/Contents/Developer";
      };
    in
    {
      # TODO: Generic darwin shell. Must use what xcode provides...
      # Seems impossible as the xcode relies on dscl to read home directory,
      # and by default, nixbld users are using /var/empty, which breaks xcode.
      # Until someday we can find a way to make xcode using a writable dir...
      toolchain.gcc.enable = false;

      # No cross compile is making:
      environment.packages = with pkgs; [
        cmake
        pkg-config
      ];

      # Even we're in NoCC, we can still use nix libraries with nix's pkg-config.
      variant.shell.buildInputs = with pkgs; [
        boost
        lua5_4
        bzip2
        xar
      ];

      # make release && make install; may need to re-login your account to make it work
      environment.make = {
        # Setup the SDK here, applies to make only to avoid polluting the shell:
        extra = ''
          export PATH="${sdk.path}/Toolchains/XcodeDefault.xctoolchain/usr/bin:${sdk.path}/usr/bin:${
            lib.makeBinPath (
              with pkgs.darwin;
              [
                file_cmds
                shell_cmds
                text_cmds
              ]
            )
          }:$PATH"
          export SDKROOT="${sdk.path}/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk"
          export PLUM_TAG="prelude essay"
          export MACOSX_DEPLOYMENT_TARGET="${sdk.version}"
        '';

        targets.init = ''
          git reset --hard
          git submodule update --init --recursive
          git submodule foreach --recursive git reset --hard

          git clean -fdx -e .direnv -e .envrc
          git submodule foreach --recursive git clean -fdx

          pushd librime
          git fetch
          git checkout 1.15.0
          git submodule update --init --recursive
          bash install-plugins.sh hchunhui/librime-lua lotem/librime-octagram rime/librime-predict
          patch -p1 < "${inputs.self}/pkgs/patches/librime-temp-ascii.patch"
          popd
        '';

        targets.clean = ''
          git clean -fdx -e .direnv -e .envrc
          git submodule foreach --recursive git clean -fdx
        '';
      };
    };
}
