{
  self,
  nixpkgs,
  colmena,
  nixos-anywhere,
  ...
}:

system:

let
  pkgs = nixpkgs.legacyPackages.${system};

  # Patched of colmena:
  colmenaPackage = self.lib.patches colmena.packages.${system}.colmena [
    ./patches/colmena-nix-store-sign.patch
  ];

  # The package of burn:
  burn = ''
    set -uex

    B_THIS="$(hostname)"
    B_THAT="''${1:-}"

    if [[ ! -d "asterisk" ]]; then
      echo "Run me in project root!"
      exit 1
    fi

    sed -i -E 's!(basedir = )[^;]+\;$!\1"'"$PWD/asterisk"'";!' \
      lib/common/config/secrets.nix
  '';

  burnSwitch = pkgs.writers.writeBashBin "burn" ''
    ${burn}

    B_COLMENA=(colmena --show-trace --experimental-flake-eval)
    if [[ "$B_THAT" == "" || "$B_THAT" == "$B_THIS" ]]; then
      B_HWCONF="mach/$B_THIS/hardware-configuration.nix"
      sudo nixos-generate-config --show-hardware-config --no-filesystems \
        > "$B_HWCONF"
      "''${B_COLMENA[@]}" apply-local --sudo --verbose

      # Try updateing the database for command-not-found as well:
      sudo nix-channel --add https://nixos.org/channels/nixos-unstable nixos
      sudo nix-channel --update nixos
    else
      "''${B_COLMENA[@]}" apply --on "$B_THAT" --verbose --keep-result \
        --sign "asterisk/$B_THIS/nix-key"
    fi
  '';

  burnInstall = pkgs.writers.writeBashBin "burn-install" ''
    ${burn}
    test -n "$1"

    B_HWCONF="mach/$B_THAT/hardware-configuration.nix"
    if [[ ! -f "$B_HWCONF" ]]; then
      echo "{ ... }: { }" > "$B_HWCONF"
    fi

    B_NIX=(nix --extra-experimental-features "nix-command flakes" --accept-flake-config)
    B_DEPLOY=".#colmenaHive.deploymentConfig.$B_THAT"
    B_KEYS="$("''${B_NIX[@]}" eval --json "$B_DEPLOY.keys" \
      | jq -r 'to_entries[]
        | select(.value.user == "root" and .value.uploadAt == "pre-activation")
        | [.value.keyFile, .value.path] | @tsv')"

    read -r B_HOST B_PORT < \
      <("''${B_NIX[@]}" eval --json "$B_DEPLOY" --apply "a:[a.targetHost a.targetPort]" | jq -r '@tsv')
    B_HOST="root@$B_HOST"
    if [[ "$B_PORT" == "" || "$B_PORT" == "null" ]]; then
      B_PORT=22
    fi

    B_INSTALL=(nixos-anywhere --target-host "$B_HOST" -p "$B_PORT"
      --generate-hardware-config nixos-generate-config "$B_HWCONF"
      --flake ".#$B_THAT")

    # Format disk:
    "''${B_INSTALL[@]}" --phases kexec,disko
    B_SSHOPTS=(-o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no)
    ssh "''${B_SSHOPTS[@]}" -p "$B_PORT" "$B_HOST" -- "
      umount -R /mnt/run
      mount -m -t tmpfs -o rw,nosuid,nodev,mode=755 tmpfs /mnt/run
      mount -m -t ramfs -o rw,nosuid,nodev,relatime,mode=750 ramfs /mnt/run/keys
    "

    # Upload keys:
    while read -r B_KEY_FROM B_KEY_TO; do
      if [[ "$B_KEY_TO" != "/run/keys/"* ]]; then
        continue
      fi
      echo "key: $B_KEY_FROM -> $B_KEY_TO"
      scp "''${B_SSHOPTS[@]}" -P "$B_PORT" "$B_KEY_FROM" "$B_HOST:/mnt$B_KEY_TO"
    done <<< "$B_KEYS"

    # Real switch:
    "''${B_INSTALL[@]}" --phases install,reboot
  '';
in
pkgs.mkShell {
  # This will import/inherit packages to this shell from `inputsFrom` packages.
  # e.g. if `inputsFrom = [ linux.dev ]` will make gcc,gnumake and other deps
  #      available to this shell, avoiding have duplicated `packages`.
  inputsFrom = [ ];

  packages = with pkgs; [
    gnused
    jq

    # RDepends:
    nixos-anywhere.packages.${system}.nixos-anywhere
    colmenaPackage

    # Real stuff:
    burnSwitch
    burnInstall
  ];

  shellHook = ''
    echo "burn [hostname || $(hostname)]"
    echo "burn-install [hostname]"
  '';
}
