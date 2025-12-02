{
  lib,
  n9,
  pkgsStatic,
  python3Packages,
  runCommand,
  writers,
  qemu_kvm,
  virtiofsd,
  busybox,
  ...
}:

# https://github.com/zyklotomic/virtme-ng-flake.nix/blob/master/flake.nix

let
  src = n9.sources.virtme-ng;

  busybox-only = runCommand "busybox-only" { } ''
    mkdir -p "$out/bin"
    cp ${busybox}/bin/busybox "$out/bin/"
  '';

  # MUST static for --root to work:
  virtme-ng-init = pkgsStatic.rustPlatform.buildRustPackage {
    pname = "virtme-ng-init";
    inherit src;
    inherit (src) version;
    cargoHash = "sha256-3+MDf6pescqPnsQBOODZJ7ic2tqxh5LPvHIMouUkhjI=";
    sourceRoot = "virtme-ng-src/virtme_ng_init";

    # Includes other things, to compatible with really "bare" environment, e.g. docker.
    # https://github.com/NixOS/nix/blob/324bfd82dca67c3189b0d218160da30a5e9b7637/docker.nix#L377
    # We include everything that equals when boot up, remains are let to direnv.
    patches = [ ./patches/virtme-ng-nix-path.patch ];
    preConfigure = ''
      echo -n "/nix/var/nix/profiles/default/bin:/nix/var/nix/profiles/default/sbin:" > src/nix-path
      echo -n "${lib.makeBinPath [ busybox-only ]}" >> src/nix-path
    '';
  };
in
python3Packages.buildPythonPackage {
  pname = "virtme-ng";
  inherit src;
  inherit (src) version;

  patches = [ ./patches/virtme-ng-sshd.nix ];

  configurePhase = ''
    export BUILD_VIRTME_NG_INIT=1
    cp -r "${virtme-ng-init}/bin/." virtme/guest/bin/
  '';

  # We patch it ourselves, to ensure --root runs scripts properly without /nix
  dontPatchShebangs = true;

  propagatedBuildInputs = with python3Packages; [
    argcomplete
    requests
  ];

  # Fake cargo and strip, we have already built ourselves.
  nativeBuildInputs = [
    (writers.writeBashBin "cargo" "echo SKIP CARGO")
    (writers.writeBashBin "strip" "echo SKIP STRIP")
  ];

  dependencies =
    (lib.map (
      n:
      writers.writeBashBin n ''
        # prefer security wrapped qemu (for rootless tun):
        if [[ -x "/run/wrappers/bin/${n}" ]]; then
          exec "/run/wrappers/bin/${n}" "$@"
        else
          exec "${qemu_kvm}/bin/${n}" "$@"
        fi
      ''
    ) [ "qemu-system-x86_64" ])
    ++ [ virtiofsd ];

  meta = {
    homepage = "https://github.com/arighi/virtme-ng";
    license = with lib.licenses; [ gpl2 ];
  };
}
