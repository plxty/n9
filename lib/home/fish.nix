{ pkgs, ... }:

let
  plugin = pkg: { inherit (pkg) name src; };
  tideToken = "003";
in
{
  programs = {
    fish = {
      enable = true;

      plugins = with pkgs.fishPlugins; [
        (plugin fzf-fish)
        (plugin tide)
        (plugin puffer)
        {
          name = "upto";
          src = pkgs.fetchFromGitHub {
            owner = "Markcial";
            repo = "upto";
            rev = "2d1f35453fb55747d50da8c1cb1809840f99a646";
            hash = "sha256-Lv2XtP2x9dkIkUUjMBWVpAs/l55Ztu7gIjKYH6ZzK4s=";
          };
        }
      ];

      functions = {
        # https://superuser.com/a/1721923
        __fish_save_most_recent_dir = {
          body = "set -U fish_most_recent_dir $PWD";
          onVariable = "PWD";
        };

        # https://github.com/kpbaks/autols.fish
        __fish_auto_ls = {
          body = "ls -AF --group-directories-first";
          onVariable = "PWD";
        };

        gitignore = "curl -sL https://www.gitignore.io/api/$argv";

        # https://github.com/IlanCosman/tide/blob/main/functions/_tide_item_nix_shell.fish
        # https://github.com/haslersn/any-nix-shell/blob/master/bin/nix-shell-info
        _tide_item_nix_shell = {
          body = ''
            if test -z "$IN_NIX_SHELL" -a -z "$IN_NIX_RUN"
              return
            end

            set -l info (echo "$ANY_NIX_SHELL_PKGS" | xargs)
            if test -n "$info"
              set info " ($info)"
            end
            _tide_print_item nix_shell $tide_nix_shell_icon' ' "$IN_NIX_SHELL$info"
          '';
        };
      };

      # FIXME: (no) local:
      shellInit = ''fish_add_path "$HOME/.local/bin"'';

      interactiveShellInit = ''
        if test "$tide_configure_token" != "${tideToken}"
          set -eU (set -U | awk '/tide/ {print $1}')

          # what `tide configure` shows:
          tide configure \
            --auto \
            --style=Lean \
            --prompt_colors='True color' \
            --show_time='24-hour format' \
            --lean_prompt_height='Two lines' \
            --prompt_connection=Disconnected \
            --prompt_spacing=Sparse \
            --icons='Few icons' \
            --transient=Yes
          set -U tide_configure_token ${tideToken}
        end

        # https://linux.overshoot.tv/wiki/ls
        set -gx LS_COLORS (string replace -a '05;' "" "$LS_COLORS")

        # No greetings:
        set fish_greeting

        # Trying if it is useful:
        set -qU fish_most_recent_dir && [ -d "$fish_most_recent_dir" ] && cd "$fish_most_recent_dir"

        # https://fishshell.com/docs/current/language.html#syntax-function-autoloading
        __fish_save_most_recent_dir
        __fish_auto_ls

        # fzf, Ctrl+(R|V) Ctrl+Alt+(L|S|P)
        set -gx FZF_DEFAULT_OPTS --bind "alt-k:clear-query"

        # https://github.com/haslersn/any-nix-shell
        ${pkgs.any-nix-shell}/bin/any-nix-shell fish | source
      '';

      shellAbbrs = {
        ra = "rg --hidden --no-ignore";
        ff = "fd --type f .";
        up = "upto";
        ze = "zoxide query";
        dh = "dirh";
        dc = "cdh";
        dr = "direnv reload";
      };
    };

    # zellij:
    zellij = {
      enable = true;
      settings = {
        simplified_ui = true;
        default_shell = "fish";
      };

      # don't replace the default shell, change ptyxis or other terminals to
      # invoke zellij:
      enableBashIntegration = false;
      enableFishIntegration = false;
    };

    # other deps:
    thefuck.enable = true;
    zoxide.enable = true;
    fzf.enable = true;
    direnv = {
      enable = true;
      nix-direnv.enable = true;
    };
  };
}
