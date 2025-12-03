# Squirrel may not package with the nixpkgs, as it's quite hard to build, and
# the xcode requires a lot interactive things to set-up.
# Therefore it's better to mantain the package my-self.
# Maybe oneday the package will be set, and everything will start going well :)
# https://github.com/NixOS/nixpkgs/blob/master/doc/stdenv/platform-notes.chapter.md

{
  n9.shell.squirrel =
    { pkgs, inputs, ... }:
    let
      sdk = rec {
        version = "15";
        xcode = "16_3";
        path = "${pkgs.darwin."xcode_${xcode}"}/Contents/Developer";
      };

      rapidjsonPatch = pkgs.fetchurl {
        url = "https://github.com/Tencent/rapidjson/commit/3b2441b87f99ab65f37b141a7b548ebadb607b96.patch";
        sha256 = "14sspnvd5rgndl0pkyrd473p66z61kpdgd9y2zwjwya1qlxgxcd8";
      };
    in
    {
      # TODO: Generic darwin shell. Must use what xcode provides...
      toolchain.gcc.enable = false;

      # No cross compile is making:
      environment.packages = with pkgs; [
        # TODO: for fish shell, this will break the ls, use "command ls" instead.
        darwin.file_cmds
        darwin.shell_cmds
        darwin.text_cmds
        cmake
        pkg-config
      ];

      # Even we're in NoCC, we can still use nix libraries with nix's pkg-config.
      variant.shell.buildInputs = with pkgs; [
        boost
        luajit
        bzip2
        xar
      ];

      # To keep my make, and to setup the SDK:
      environment.variables = {
        PATH = ''$(dirname "$(which make)"):${sdk.path}/Toolchains/XcodeDefault.xctoolchain/usr/bin:${sdk.path}/usr/bin:$PATH'';
        SDKROOT = "${sdk.path}/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk";
        PLUM_TAG = "prelude essay";
        MACOSX_DEPLOYMENT_TARGET = "${sdk.version}";
      };

      environment.make.targets.init = ''
        git reset --hard
        git clean -fdx -e .direnv -e .envrc
        git submodule update --init --recursive
        git submodule foreach --recursive git reset --hard
        git submodule foreach --recursive git clean -fdx

        pushd librime
        bash install-plugins.sh hchunhui/librime-lua lotem/librime-octagram rime/librime-predict
        git submodule update --init --recursive

        pushd deps/yaml-cpp
        sed -i.old 's/3\.4/3.5/g' CMakeLists.txt
        popd

        # https://github.com/wittrock/kythe/commit/9bb04240c4f9b8886d63bf7e745aef332be80d28
        pushd deps/opencc/deps/rapidjson-1.1.0
        sed 's|include/||g' ${rapidjsonPatch} | patch -p1
        popd

        # what's my hack?
        patch -p1 < "${inputs.self}/pkgs/patches/librime-temp-ascii.patch"
        popd
      '';

      # make clean && make && make install
      # you may need to re-login your account to make it work
      environment.make.targets.clean = ''
        git clean -fdx -e .direnv -e .envrc
        git submodule update --init --recursive
        git submodule foreach --recursive git clean -fdx
      '';
    };
}
