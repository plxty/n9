{ pkgs, ... }:

# Squirrel may not package with the nixpkgs, as it's quite hard to build, and
# the xcode requires a lot interactive things to set-up.
# Therefore it's better to mantain the package my-self.
# Maybe oneday the package will be set, and everything will start going well :)

let
  sdk = {
    version = "15";
    xcode = "16_3";
  };
in
{
  n9.shell.squirrel = {
    # TODO: Generic darwin shell.
    # https://github.com/NixOS/nixpkgs/blob/5b62148ab01f6ec8d8cfbee579ebc462c251cfab/doc/stdenv/platform-notes.chapter.md
    # https://discourse.nixos.org/t/using-darwin-sdks-from-nixpkgs-darwin-xcode/58850/2
    gcc.enable = false;
    clang.enable = true;

    # No cross compile is making:
    packages = with pkgs; [
      # TODO: for fish shell, this will break the ls, use "command ls" instead.
      darwin.file_cmds
      darwin.shell_cmds
      cmake
      pkg-config
    ];

    buildInputs = with pkgs; [
      pkgs."apple-sdk_${sdk.version}"
      boost
      luajit
      bzip2
      xar
    ];

    shellHooks = [
      # For use xcode tools, TODO: does nix already supports it?
      ''
        # To keep my make:
        make="$(which make)"
        make="$(dirname "$make")"

        export PLUM_TAG=":preset"
        export PATH="$make:${pkgs.darwin."xcode_${sdk.xcode}"}/Contents/Developer/usr/bin:$PATH"
        export MACOSX_DEPLOYMENT_TARGET="${sdk.version}"
      ''
    ];

    make = {
      prepare = ''
        git submodule update --init --recursive

        pushd librime
        bash install-plugins.sh hchunhui/librime-lua lotem/librime-octagram rime/librime-predict
        git submodule update --init --recursive

        # https://github.com/wittrock/kythe/commit/9bb04240c4f9b8886d63bf7e745aef332be80d28
        pushd deps/opencc
        patch -p1 <<'EOF'
        diff --git a/deps/rapidjson-1.1.0/rapidjson/document.h b/deps/rapidjson-1.1.0/rapidjson/document.h
        index e3e20df..b0f1f70 100644
        --- a/deps/rapidjson-1.1.0/rapidjson/document.h
        +++ b/deps/rapidjson-1.1.0/rapidjson/document.h
        @@ -316,8 +316,6 @@ struct GenericStringRef {

             GenericStringRef(const GenericStringRef& rhs) : s(rhs.s), length(rhs.length) {}

        -    GenericStringRef& operator=(const GenericStringRef& rhs) { s = rhs.s; length = rhs.length; }
        -
             //! implicit conversion to plain CharType pointer
             operator const Ch *() const { return s; }
        EOF
        popd

        # what's my hack?
        patch -p1 < "$HOME/.n9/pkgs/patches/librime-temp-ascii.patch"
        popd
      '';

      clean = ''
        git clean -fdx -e .direnv -e .envrc
        git submodule foreach --recursive git reset --hard
        git submodule foreach --recursive git clean -fdx
      '';

      # make && make install
      # you may need to re-login your account to make it work
    };
  };
}
