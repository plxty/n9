{
  pkgs,
  n9,
  inputs,
  ...
}:

let
  inherit (pkgs) system;

  # https://discourse.nixos.org/t/how-to-add-a-flake-package-to-system-configuration/14460/5
  # It can be an overlay of nixpkgs, however for simplicity...
  colmenaPackage = n9.patches inputs.colmena.packages.${system}.colmena [
    ../pkgs/patches/colmena-nix-store-sign.patch
  ];

  preBurn = ''
    set -uex

    B_THIS="$(hostname)"
    B_THAT="''${1:-}"
    B_NIX=(nix --extra-experimental-features "nix-command flakes" --accept-flake-config)
    B_SSHOPTS=(-o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no)

    if [[ ! -d asterisk ]]; then
      cd "$HOME/.n9"
      if [[ ! -d asterisk ]]; then
        echo "Run me in project root!"
        exit 1
      fi
    fi

    if [[ "$B_THAT" != "" ]]; then
      B_DEPLOY=".#colmenaHive.deploymentConfig.$B_THAT"
      read -r B_USER B_HOST B_PORT < \
        <("''${B_NIX[@]}" eval --json "$B_DEPLOY" --apply "a:[a.targetUser a.targetHost a.targetPort]" | jq -r '@tsv')
      if [[ "$B_PORT" == "" || "$B_PORT" == "null" ]]; then
        B_PORT=22
      fi
    fi

    B_UP=true
    if [[ -f .last ]]; then
      if (("$(date +%s)" - "$(stat -c %Y .last)" < 86400)); then
        B_UP=false
      fi
    fi

    if $B_UP; then
      # Pull the latest changes if have:
      git pull --rebase || true
      cd asterisk
      git pull --rebase || true
      chmod -R g-rwx,o-rwx .
      cd ..
      "''${B_NIX[@]}" flake update || true
    fi

    # Das template:
    sed -i -E 's!(path = )[^;]+\;$!\1"'"$PWD"'";!' \
      lib/nixos/essential.nix
    sed -i -E 's!(basedir = )[^;]+\;$!\1"'"$PWD/asterisk"'";!' \
      lib/generic/config/keys.nix
  '';

  postBurn = ''
    touch .last
  '';

  burnSwitch = pkgs.writers.writeBashBin "burn" ''
    ${preBurn}
    B_COLMENA=(colmena --show-trace --experimental-flake-eval)
    B_HWCONF=(sudo nixos-generate-config --show-hardware-config --no-filesystems)

    if [[ "$B_THAT" == "" || "$B_THAT" == "$B_THIS" ]]; then
      # Try to keep sudo until finished (warning! tricky! unsafe!), yay sudoloop:
      sudo -v
      trap 'pkill -P $$' SIGINT SIGTERM EXIT
      {
        # "Wakeup" the sleeping parent when exit normally or abnormally:
        trap 'pkill -P $$ sleep' EXIT

        # For hosts that mismatch with local, suggest `hostname xxx`:
        "''${B_HWCONF[@]}" > "hosts/$B_THIS/hardware-configuration.nix"
        "''${B_COLMENA[@]}" apply-local --sudo --verbose

        if $B_UP; then
          # Try updateing the database for command-not-found as well:
          sudo nix-channel --add https://mirrors.ustc.edu.cn/nix-channels/nixos-unstable nixos
          sudo nix-channel --update nixos || true
        fi

        # The `sleep` will be killed whether successful or not...
        ${postBurn}
      } &
      while jobs %%; do sudo -v; sleep 180; done
    else
      ssh "''${B_SSHOPTS[@]}" -p "$B_PORT" "$B_USER@$B_HOST" -- "''${B_HWCONF[@]}" \
        > "hosts/$B_THAT/hardware-configuration.nix"
      "''${B_COLMENA[@]}" apply --on "$B_THAT" --verbose --keep-result \
        --no-substitute --sign "asterisk/$B_THIS/nix-key"
      ${postBurn}
    fi
  '';

  burnInstall = pkgs.writers.writeBashBin "fire" ''
    ${preBurn}
    test -n "$B_THAT"

    B_HWCONF="hosts/$B_THAT/hardware-configuration.nix"
    if [[ ! -f "$B_HWCONF" ]]; then
      echo "{ ... }: { }" > "$B_HWCONF"
    fi

    B_KEYS="$("''${B_NIX[@]}" eval --json "$B_DEPLOY.keys" \
      | jq -r 'to_entries[]
        | select(.value.user == "root" and .value.uploadAt == "pre-activation")
        | [.value.keyFile, .value.path] | @tsv')"

    B_INSTALL=(nixos-anywhere --target-host "root@$B_HOST" -p "$B_PORT"
      --generate-hardware-config nixos-generate-config "$B_HWCONF" --flake ".#$B_THAT")

    # Format disk:
    "''${B_INSTALL[@]}" --phases kexec,disko
    B_SSHOPTS=(-o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no)
    ssh "''${B_SSHOPTS[@]}" -p "$B_PORT" "root@$B_HOST" -- "mkdir -p /mnt/etc/nixos/keys"

    # Upload keys, TODO: colmena?
    while read -r B_KEY_FROM B_KEY_TO; do
      if [[ "$B_KEY_TO" != "/etc/nixos/keys/"* ]]; then
        continue
      fi
      echo "key: $B_KEY_FROM -> $B_KEY_TO"
      scp "''${B_SSHOPTS[@]}" -P "$B_PORT" "$B_KEY_FROM" "root@$B_HOST:/mnt$B_KEY_TO"
    done <<< "$B_KEYS"

    # Real switch:
    "''${B_INSTALL[@]}" --phases install,reboot
    ${postBurn}
  '';
in
pkgs.mkShell {
  name = "burn";

  packages = with pkgs; [
    # RDepends:
    gnused
    jq
    inputs.nixos-anywhere.packages.${system}.default
    colmenaPackage

    # Real stuff:
    burnSwitch
    burnInstall
  ];
}
