{
  n9.shell.burn =
    {
      n9,
      pkgs,
      inputs,
      ...
    }:
    let
      burn = pkgs.writers.writeBashBin "burn" ''
        set -uex

        if which hostname; then
          B_THIS="$(hostname)"
        else
          B_THIS="$HOSTNAME"
        fi
        B_THAT="''${1:-}"
        shift 1 || true

        if [[ ! -d asterisk ]]; then
          echo "Run me in project root!"
          exit 1
        fi

        B_NIX=(nix --extra-experimental-features "nix-command flakes" --accept-flake-config)
        if [[ -f asterisk/.github_token ]]; then
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
          "''${B_NIX[@]}" flake update || true
          niv update
          touch .last
        fi

        # Das template:
        echo "\"$(realpath "$PWD")\"" > lib/dir.nix

        # Fake sudo if not have:
        if ! which sudo && [[ "$(id -u)" -eq "0" ]]; then
          function sudo() {
            if [[ "$1" == "-v" ]]; then
              true
            else
              "$@"
            fi
          }
          export -f sudo
        fi

        B_COLMENA=(colmena --show-trace)
        if [[ "$B_THAT" == "" || "$B_THAT" == "$B_THIS" ]]; then
          # Try to keep sudo until finished (warning! tricky! unsafe!), yay sudoloop:
          sudo -v
          trap 'pkill -P $$' SIGINT SIGTERM EXIT
          {
            # "Wakeup" the sleeping parent when exit normally or abnormally:
            trap 'pkill -P $$ sleep' EXIT

            # Maybe a pre-defined distro, e.g. orbstack
            if [[ -f /etc/nixos/configuration.nix ]]; then
              mkdir -p "config/system/$B_THIS/inherit"
              cp -a /etc/nixos/*.nix "config/system/$B_THIS/inherit/"
            fi

            # For hosts that mismatch with local, suggest `sudo hostname xxx`:
            "''${B_COLMENA[@]}" apply-local --verbose

            # The `sleep` will be killed whether successful or not...
          } &
          while jobs %%; do sudo -v; sleep 180; done
        else
          "''${B_COLMENA[@]}" apply --on "$B_THAT" --verbose --keep-result \
            --no-substitute --sign "asterisk/$B_THIS/nix-key"
        fi
      '';
    in
    {
      environment.packages = with pkgs; [
        # Colmena:
        (n9.patch inputs.colmena.packages.${stdenv.system}.colmena "colmena-taste")

        # RDepends:
        getent # upload-keys
        (pkgs.writers.writeBashBin "niv" ''
          # Specify our own sources, don't want to patch it :/
          exec ${niv}/bin/niv -s lib/sources.json "$@"
        '')
        procps # pkill

        # Real stuff:
        burn
      ];
    };
}
