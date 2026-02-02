#!/usr/bin/env bash

set -uex

if [[ ! -d asterisk ]]; then
  echo "Run me in project root!"
  exit 1
fi

if which hostname; then
  B_THIS="$(hostname)"
else
  B_THIS="$HOSTNAME"
fi

B_UP=false
B_THAT="$B_THIS"
while true; do
  case "${1:-}" in
  "")
    break ;;
  "--fuel")
    B_UP=true ;;
  *)
    B_THAT="$1" ;;
  esac
  shift 1 || true
done

B_NIX=(nix --extra-experimental-features "nix-command flakes" --accept-flake-config)
B_NIX_SHELL=(nix-shell)
if [[ -f asterisk/.github_token ]]; then
  # shellcheck disable=SC2155
  export NIV_GITHUB_TOKEN="$(< asterisk/.github_token)"
  B_NIX+=(--option access-tokens "github.com=$NIV_GITHUB_TOKEN")
  B_NIX_SHELL+=(--option access-tokens "github.com=$NIV_GITHUB_TOKEN")
fi

if $B_UP; then
  set +e
  # Pull the latest changes if have:
  git pull --rebase
  cd asterisk
  git pull --rebase
  chmod -R g-rwx,o-rwx .
  cd ..
  "${B_NIX[@]}" flake update --flake '.?submodules=1'
  if [[ -f lib/sources.json ]]; then
    niv update
  fi
  "${B_NIX_SHELL[@]}" maintainers/scripts/update.nix --arg nu true
  set -e
fi

# Das template:
echo "\"$(realpath "$PWD")\"" > lib/dir.nix
trap 'git restore lib/dir.nix; pkill -P $$' SIGINT SIGTERM EXIT

# For debugging: --show-trace
B_COLMENA=(colmena "$@")
if [[ "$B_THAT" == "" || "$B_THAT" == "$B_THIS" ]]; then
  # Try to keep sudo until finished (warning! tricky! unsafe!), yay sudoloop:
  which sudo > /dev/null && sudo -v
  {
    # For hosts that mismatch with local, suggest `sudo hostname xxx`:
    trap 'pkill -P $$ sleep' EXIT
    "${B_COLMENA[@]}" apply-local --verbose
  } &
  # The ctrl-c are handled here:
  while jobs %%; do sudo -v || true; sleep 180; done
else
  "${B_COLMENA[@]}" apply --on "$B_THAT" --verbose --keep-result \
    --no-substitute --sign "asterisk/$B_THIS/nix-key"
fi
