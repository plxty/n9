{
  lib,
  rsync,
  writers,
  pkgsStatic,
  ...
}:

let
  proot-rs = pkgsStatic.proot-rs;
in
writers.writeBashBin "nix-pack-closure" { } ''
  set -uex

  # packelf $(which drgn) drgn-vXXX-x86_64
  # -> drgn-vXXX-x86_64.tar.gz
  src="$(nix-store --query "$1")"
  dst="$2"

  # preparing working directory:
  tmp="$(mktemp -d)"
  trap 'rm -rf "$tmp"' SIGINT SIGTERM EXIT
  wd="$tmp/$dst"
  mkdir -p "$wd/lib" "$wd/bin"
  pushd "$wd"

  # rsync all required files:
  nix-store --query --include-outputs --requisites "$src" \
    | xargs -I{} "${lib.getExe rsync}" -a --chmod=Du+w,Fu+w {} lib/
  cp "${proot-rs}/bin/proot-rs" bin/

  # making wrappers:
  for bin in "$src/bin/"*; do
    wrapper="bin/$(basename "$bin")"
    (
      echo "#!/usr/bin/env bash"
      echo 'BASH_DIRECTORY="$(realpath "$(dirname "''${BASH_SOURCE[0]}")/..")"'
      echo 'exec "$BASH_DIRECTORY/bin/proot-rs" -b "$BASH_DIRECTORY/lib:/nix/store" "'"$bin"'" "$@"'
    ) > "$wrapper"
    chmod +x "$wrapper"
  done

  # tarball:
  popd
  tar -czf "$dst.tar.gz" --owner=0 --group=0 --no-same-owner --no-same-permissions \
    -C "$tmp" "$dst"
''
