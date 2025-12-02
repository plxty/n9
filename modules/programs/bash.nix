{ n9, pkgs, ... }:
{
  options.users = n9.mkAttrsOfSubmoduleOption {
    config.variant.home-manager.programs = {
      bash = {
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

      # TODO: Fully intergarting with bash? May only work in fish.
      direnv = {
        enable = true;
        nix-direnv.enable = true;
      };
      fzf.enable = true;
      zoxide.enable = true;
    };
  };
}
