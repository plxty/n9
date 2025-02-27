{
  inputs = {
    nixpkgs.follows = "n9/nixpkgs";
    n9.url = "./lib";
    colmena.follows = "n9/colmena";
    nixos-anywhere = {
      url = "github:nix-community/nixos-anywhere";
      inputs.nixpkgs.follows = "n9/nixpkgs";
    };
  };

  outputs =
    {
      nixpkgs,
      n9,
      colmena,
      nixos-anywhere,
      ...
    }:
    let
      # @see nix/flake.nix
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];

      mkDevShell =
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};

          # Patched of colmena:
          colmenaPackage = n9.lib.patches colmena.packages.${system}.colmena [
            ./lib/patches/colmena-nix-store-sign.patch
            ./lib/patches/colmena-keep-result-dir.patch
          ];

          # The package of burn:
          burn = ''
            set -uex

            B_SOURCE="$PWD"
            B_THIS="$(hostname)"
            B_THAT="''${1:-}"

            if [[ ! -d "asterisk" ]]; then
              echo "Run me in project root!"
              exit 1
            fi

            rm -rf /tmp/n9
            rsync -a --exclude .git --exclude asterisk "$B_SOURCE/" /tmp/n9
            cd /tmp/n9
            find mach -name default.nix -exec sed -i "s!@ASTERISK@!$B_SOURCE/asterisk!g" {} \;
          '';

          burnSwitch = pkgs.writers.writeBashBin "burn" ''
            ${burn}

            B_COLMENA=(colmena --show-trace --experimental-flake-eval)
            if [[ "$B_THAT" == "" || "$B_THAT" == "$B_THIS" ]]; then
              B_HWCONF="mach/$B_THIS/hardware-configuration.nix"
              sudo nixos-generate-config --show-hardware-config --no-filesystems > "$B_HWCONF"
              "''${B_COLMENA[@]}" apply-local --sudo --verbose
              cp -f "$B_HWCONF" "$B_SOURCE/$B_HWCONF"
            else
              "''${B_COLMENA[@]}" apply --on "$B_THAT" --verbose --keep-result "$B_SOURCE" \
                --sign "$B_SOURCE/asterisk/$B_THIS/nix-key"
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
              | jq -r 'to_entries[] | select(.value.user == "root" and .value.uploadAt == "pre-activation")
                | [.value.keyFile, .value.path] | @tsv')"

            read -r B_HOST B_PORT < \
              <("''${B_NIX[@]}" eval --json "$B_DEPLOY" --apply "a:[a.targetHost a.targetPort]" | jq -r '@tsv')
            B_HOST="root@$B_HOST"
            if [[ "$B_PORT" == "" || "$B_PORT" == "null" ]]; then
              B_PORT=22
            fi

            B_INSTALL=(nixos-anywhere --generate-hardware-config nixos-generate-config "$B_HWCONF"
              --flake ".#$B_THAT" --target-host "$B_HOST" -p "$B_PORT")

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
            cp -f "$B_HWCONF" "$B_SOURCE/$B_HWCONF"
          '';
        in
        pkgs.mkShell {
          # This will import/inherit packages to this shell from `inputsFrom` packages.
          # e.g. if `inputsFrom = [ linux.dev ]` will make gcc,gnumake and other deps
          #      available to this shell, avoiding have duplicated `packages`.
          inputsFrom = [ ];

          packages = with pkgs; [
            rsync
            findutils
            gnused
            jq

            nixos-anywhere.packages.${system}.nixos-anywhere # expose for testing
            colmenaPackage
            burnSwitch
            burnInstall
          ];

          shellHook = ''
            echo "burn [hostname || $(hostname)]"
            echo "burn-install [hostname]"
          '';
        };
    in
    {
      devShell = nixpkgs.lib.genAttrs systems mkDevShell;
    };

  nixConfig = {
    substituters = [
      "https://mirror.sjtu.edu.cn/nix-channels/store"
      "https://mirrors.ustc.edu.cn/nix-channels/store"
      "https://mirrors.sustech.edu.cn/nix-channels/store"
    ];
  };
}
