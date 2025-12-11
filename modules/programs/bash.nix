{ n9, pkgs, ... }:
{
  options.users = n9.mkAttrsOfSubmoduleOption { } {
    config.variant.home-manager.programs = {
      bash = {
        enable = true;

        bashrcExtra = ''
          # There's a case that the the /etc/profile will resets PATH after
          # bash --login twice, making nix profiles' PATH lost, workaround here:
          # Have no idea why apps need do login twice...
          if [[ "$__ETC_PROFILE_NIX_SOURCED" == "1" ]]; then
            for NIX_LINK in $NIX_PROFILES; do
              if [[ "$PATH" != *"$NIX_LINK"* ]]; then
                export PATH="$NIX_LINK/bin:$PATH"
              fi
            done
            unset NIX_LINK
          fi

          # Returns early for non-interactive, and ensure it's "succeeded".
          # FIXME: The upstream should get it fixed...
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
