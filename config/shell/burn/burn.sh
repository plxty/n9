#!/usr/bin/env bash

set -uex

if which hostname; then
  B_THIS="$(hostname)"
else
  B_THIS="$HOSTNAME"
fi
B_THAT="${1:-}"
shift 1 || true

if [[ ! -d asterisk ]]; then
  echo "Run me in project root!"
  exit 1
fi

B_NIX=(nix --extra-experimental-features "nix-command flakes" --accept-flake-config)
if [[ -f asterisk/.github_token ]]; then
  # shellcheck disable=SC2155
  export NIV_GITHUB_TOKEN="$(< asterisk/.github_token)"
  B_NIX+=(--option access-tokens "github.com=$NIV_GITHUB_TOKEN")
fi

B_UP=true
if [[ -f .last ]] && (("$(date +%s)" - "$(stat -c %Y .last)" < 86400)); then
  B_UP=false
fi

if $B_UP; then
  # Pull the latest changes if have:
  git pull --rebase || true
  cd asterisk
  git pull --rebase || true
  chmod -R g-rwx,o-rwx .
  cd ..
  "${B_NIX[@]}" flake update || true
  if [[ -f lib/sources.json ]]; then
    niv update
  fi
  touch .last
fi

# Das template:
echo "\"$(realpath "$PWD")\"" > lib/dir.nix

# Trap will be replaced, so we do everything here... TODO: Trap arrays?
trap 'git restore lib/dir.nix; pkill -P $$' SIGINT SIGTERM EXIT

# For debugging: --show-trace
B_COLMENA=(colmena "$@")
if [[ "$B_THAT" == "" || "$B_THAT" == "$B_THIS" ]]; then
  # Try to keep sudo until finished (warning! tricky! unsafe!), yay sudoloop:
  which sudo > /dev/null && sudo -v
  {
    # "Wakeup" the sleeping parent when exit normally or abnormally:
    trap 'pkill -P $$ sleep' EXIT

    # Maybe a pre-defined distro, e.g. orbstack
    if [[ -f /etc/nixos/configuration.nix ]]; then
      mkdir -p "config/system/$B_THIS/inherit"
      cp -a /etc/nixos/*.nix "config/system/$B_THIS/inherit/"
    fi

    # For hosts that mismatch with local, suggest `sudo hostname xxx`:
    "${B_COLMENA[@]}" apply-local --verbose

    # The `sleep` will be killed whether successful or not...
  } &
  while jobs %%; do sudo -v || true; sleep 180; done
else
  "${B_COLMENA[@]}" apply --on "$B_THAT" --verbose --keep-result \
    --no-substitute --sign "asterisk/$B_THIS/nix-key"
fi
