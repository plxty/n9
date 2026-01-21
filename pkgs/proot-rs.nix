{
  lib,
  n9,
  stdenv,
  rustPlatform,
  cargo-make,
  ...
}:

let
  pkgInfo = rec {
    src = n9.sources.proot-rs;
    version = n9.trimRev src;
    cargoDeps = rustPlatform.fetchCargoVendor {
      inherit src;
      hash = "sha256-NOsKXth+gIhDsNDoP2l3J64BpN8YN22RJx+nzYt69vU=";
    };
  };

  # The shim is always static, using cargo-make will override nix flags, and
  # it should be fine here, TODO: try not to?
  loader-shim = rustPlatform.buildRustPackage (
    pkgInfo
    // {
      pname = "proot-rs-loader-shim";
      postPatch = lib.optionalString stdenv.hostPlatform.isMusl ''
        sed -i 's/ -C link-self-contained=no//g' Makefile.toml
      '';

      nativeBuildInputs = [ cargo-make ];
      buildPhase = "cargo make --profile production build-loader";
      installPhase = "cp target/release/loader-shim $out";
      doCheck = false;
    }
  );
in
rustPlatform.buildRustPackage (
  pkgInfo
  // {
    pname = "proot-rs";
    postPatch = "cp ${loader-shim} proot-rs/src/kernel/execve/loader-shim";

    # Still requires some low-level hacks:
    env.RUSTC_BOOTSTRAP = "1";

    # Requires a rootfs:
    doCheck = false;

    # For lib.getExe:
    meta.mainProgram = "proot-rs";
  }
)
