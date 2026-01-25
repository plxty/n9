{
  lib,
  fetchFromGitHub,
  stdenv,
  rustPlatform,
  cargo-make,
  unstableGitUpdater,
  ...
}:

let
  pkgInfo = rec {
    src = fetchFromGitHub {
      owner = "plxty";
      repo = "proot-rs";
      rev = "e7fa296bd91463adf9911f6cc6616c8132a145cb";
      sha256 = "AzH1rZFqEH8sovZZfJykvsEmCedEZWigQFHWHl6/PdE=";
    };
    version = "0-unstable-2026-01-22";
    # TODO: Automatically update? Will it?
    cargoDeps = rustPlatform.fetchCargoVendor {
      inherit src;
      hash = "sha256-NOsKXth+gIhDsNDoP2l3J64BpN8YN22RJx+nzYt69vU=";
    };
    passthru.updateScript = unstableGitUpdater { hardcodeZeroVersion = true; };
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
