{
  lib,
  fetchurl,
  writers,
  curl,
  jq,
  nix,
  nix-prefetch-scripts,
  runCommand,
  ...
}:

let
  version = "202603032223";
  pname = "geodat";
  commit = "f26d300e50b09b9f4292988b890bdb69e19a761b";

  src = {
    geoip = {
      url = "https://github.com/Loyalsoldier/v2ray-rules-dat/releases/download/${version}/geoip.dat";
      hash = "sha256-X33IirmNViJywrNpbUIhT4JZ9h1Llw25PAB6umBUsEs=";
    };
    geosite = {
      url = "https://github.com/Loyalsoldier/v2ray-rules-dat/releases/download/${version}/geosite.dat";
      hash = "sha256-fnOqhhRsKqewW9jy7JeDQ+q3GrLj6ynmQ8a7bM0DMHU=";
    };
    google = {
      url = "https://github.com/Loyalsoldier/geoip/raw/refs/heads/${commit}/text/google.txt";
      hash = "sha256-952noX5ac8Y9fL/o7nX9m89wtzBAtUFTJ5JtyHCaaoE=";
    };
  };

  updateScript = writers.writeBash "update.sh" ''
    set -xeuo pipefail
    export PATH="${
      lib.makeBinPath [
        curl
        jq
        nix
        nix-prefetch-scripts
      ]
    }:$PATH"

    # $PWD from where you run the nix-shell, so n9 root here:
    cd pkgs
    tmp="$(mktemp -u)"
    cp geodat.nix "$tmp"
    trap "rm -f $tmp" SIGTERM SIGINT EXIT

    function curl() {
      args=(-s)
      if [[ -f "../asterisk/.github_token" ]]; then
        args+=(--header "Authorization: Bearer $(< "../asterisk/.github_token")")
      fi
      command curl "''${args[@]}" "$@"
    }

    function update_rules() {
      tag="$(curl -s https://api.github.com/repos/Loyalsoldier/v2ray-rules-dat/releases/latest | \
        jq -r '.tag_name')"
      if grep -q "$tag" geodat.nix; then
        return
      fi

      geoip="$(nix-prefetch-url "https://github.com/Loyalsoldier/v2ray-rules-dat/releases/download/$tag/geoip.dat")"
      geoip="$(nix --extra-experimental-features nix-command hash convert --to sri --hash-algo sha256 "$geoip")"
      sed -i "s!${src.geoip.hash}!$geoip!g" "$tmp"

      geosite="$(nix-prefetch-url "https://github.com/Loyalsoldier/v2ray-rules-dat/releases/download/$tag/geosite.dat")"
      geosite="$(nix --extra-experimental-features nix-command hash convert --to sri --hash-algo sha256 "$geosite")"
      sed -i "s!${src.geosite.hash}!$geosite!g" "$tmp"

      # commit version:
      sed -i "s/${version}/$tag/g" "$tmp"
    }

    function update_text() {
      commit="$(curl -s https://api.github.com/repos/Loyalsoldier/geoip/branches/release | \
        jq -r '.commit.sha')"
      if grep -q "$commit" geodat.nix; then
        return
      fi

      google="$(nix-prefetch-url "https://raw.githubusercontent.com/Loyalsoldier/geoip/$commit/text/google.txt")"
      google="$(nix --extra-experimental-features nix-command hash convert --to sri --hash-algo sha256 "$google")"
      sed -i "s!${src.google.hash}!$google!g" "$tmp"

      # commit commit:
      sed -i "s/${commit}/$commit/g" "$tmp"
    }

    update_rules
    update_text
    cp "$tmp" geodat.nix
  '';
in
runCommand "${pname}-${version}"
  {
    inherit pname version;
    passthru.updateScript = "${updateScript}";
  }
  ''
    mkdir -p "$out"
    cp "${fetchurl src.geoip}" "$out/geoip.dat"
    cp "${fetchurl src.geosite}" "$out/geosite.dat"
    cp "${fetchurl src.google}" "$out/google.txt"
  ''
