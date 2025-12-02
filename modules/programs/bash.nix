{
  config,
  lib,
  n9,
  pkgs,
  ...
}:

let
  rConfig = config;
in
{
  options.users = n9.mkAttrsOfSubmoduleOption (
    { config, ... }:
    let
      cfg = config.programs.bash;
    in
    {
      options.programs.bash.enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
      };

      config.variant.home-manager = lib.mkIf cfg.enable {
        # Keep most of my CLI stuff here:
        home.packages =
          with pkgs;
          [
            # basic
            wget
            which
            coreutils
            findutils
            procps
            hostname
            less
            more
            ncurses
            gnutar
            xz
            gnugrep
            patch
            gawk
            gnused
            getent

            # enhancements
            p7zip
            unrar
            jq
            yq
            nix-tree
            pstree
            binutils
            moreutils
            file
            dig
            binwalk
            bc
            ncdu
            smartmontools
            rsync
            socat
            lrzsz
            # python3 # conflict with jupyter
            jupyter # https://github.com/NixOS/nixpkgs/issues/255923
          ]
          ++ lib.optionals pkgs.stdenv.isLinux [
            # basic
            util-linux

            # enhancements
            iproute2
            iputils
            tcpdump
            strace
            sysstat
            lm_sensors
            bpftrace
            rConfig.variant.nixos.boot.kernelPackages.perf
          ];

        programs.bash = {
          enable = true;

          # https://github.com/nix-community/home-manager/blob/release-25.05/modules/programs/bash.nix
          # FIXME: The upstream should get it fixed... Always make non-interactive shell returns zero.
          bashrcExtra = ''
            # Returns early for non-interactive, and ensure it's "succeeded".
            if [[ $- != *i* ]]; then
              return
            fi
          '';

          # https://nixos.wiki/wiki/Fish, but only ssh:
          initExtra = ''
            case "$(${pkgs.procps}/bin/ps --no-header --pid=$PPID --format=comm)" in
            "sshd-session"|"sshd")
              if [[ -z ''${BASH_EXECUTION_STRING} ]]; then
                shopt -q login_shell && LOGIN_OPTION='--login' || LOGIN_OPTION=""
                exec ${pkgs.fish}/bin/fish $LOGIN_OPTION
              fi
              ;;
            esac
          '';
        };
      };
    }
  );
}
