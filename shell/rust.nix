{ pkgs, inputs, ... }:

# https://nixos.wiki/wiki/Rust
# To keep minimal currently, may place to lib/rust.nix and referenced by other projects.
let
  inherit (inputs.nixpkgs) lib;
in
pkgs.mkShell {
  name = "rust";

  buildInputs = with pkgs; [
    clang
    llvmPackages.bintools
    rustup
  ];

  # https://github.com/rust-lang/rust-bindgen#environment-variables
  LIBCLANG_PATH = pkgs.lib.makeLibraryPath [ pkgs.llvmPackages_latest.libclang.lib ];
  BINDGEN_EXTRA_CLANG_ARGS = (lib.map (a: ''-I"${a}/include"'') [ pkgs.glibc.dev ]) ++ [
    ''-I"${pkgs.llvmPackages_latest.libclang.lib}/lib/clang/${pkgs.llvmPackages_latest.libclang.version}/include"''
    ''-I"${pkgs.glib.dev}/include/glib-2.0"''
    ''-I"${pkgs.glib.out}/lib/glib-2.0/include"''
  ];

  # TODO: When there's no rust-toolchain, using system instead of stable?
  shellHook = ''
    if [[ -f rust-toolchain.toml ]]; then
      export RUSTC_VERSION="$(tomlq -r .toolchain.channel rust-toolchain.toml)"
    else
      export RUSTC_VERSION=stable
    fi

    export PATH=$PATH:$HOME/.cargo/bin
    export PATH=$PATH:$HOME/.rustup/toolchains/$RUSTC_VERSION-x86_64-unknown-linux-gnu/bin

    rustup component add rust-analyzer
    rustup show
  '';
}
