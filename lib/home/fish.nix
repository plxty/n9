{ pkgs, ... }:

let
  plugin = pkg: { inherit (pkg) name src; };
  tideToken = "1";
in
{
  home.packages = with pkgs; [
    ripgrep
    fd
    bat
  ];

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
          onEvent = "fish_postexec";
        };

        # https://github.com/kpbaks/autols.fish
        __fish_auto_ls = {
          body = "ls -AF --group-directories-first";
          onVariable = "PWD";
        };

        gitignore = "curl -sL https://www.gitignore.io/api/$argv";

        # or: direnv edit
        envrc = ''
          if test -f .envrc
            cat .envrc
          end

          set -f env $argv[1]
          if test -z "$env"
            echo "envrc [env]"
            return
          end

          read -l -P "will use env \"$env\", y? " confirm
          if test "$confirm" = "y"
            echo "use flake 'n9#\"$env\"'" | tee .envrc
            direnv allow
          end
        '';

        # https://github.com/IlanCosman/tide/blob/main/functions/_tide_item_nix_shell.fish
        # https://github.com/haslersn/any-nix-shell/blob/master/bin/nix-shell-info
        # The nix-shell will introdue some nix build environment in here, such
        # as $name or else, the mkDerivation just works like that :/
        _tide_item_nix_shell = {
          body = ''
            if test -z "$IN_NIX_SHELL" -a -z "$IN_NIX_RUN"
              return
            end

            set -f pkgs $ANY_NIX_SHELL_PKGS
            if test -n "$name" -a "$name" != "shell"
              set -a pkgs " $name"
            end
            if test -n "$pkgs"
              set pkgs (echo "$pkgs $additional_pkgs" | xargs)
              set pkgs " ($pkgs)"
            end

            _tide_print_item nix_shell $tide_nix_shell_icon' ' "$IN_NIX_SHELL$pkgs"
          '';
        };
      };

      shellInit = ''
        # FIXME: (no) local:
        fish_add_path "$HOME/.local/bin"

        # https://github.com/haslersn/any-nix-shell
        ${pkgs.any-nix-shell}/bin/any-nix-shell fish | source
      '';

      interactiveShellInit = ''
        if test "$tide_configure_token" != "${tideToken}"
          set -eU (set -U | awk '/tide/ {print $1}')

          # what `tide configure` shows:
          tide configure --auto --style=Lean --prompt_colors='True color' --show_time='24-hour format' --lean_prompt_height='Two lines' --prompt_connection=Disconnected --prompt_spacing=Sparse --icons='Few icons' --transient=Yes
          set -U tide_configure_token ${tideToken}
        end

        # No greetings:
        set fish_greeting

        # Trying if it is useful:
        if test $SHLVL -le 1
          set -qU fish_most_recent_dir && [ -d "$fish_most_recent_dir" ] && \
            cd "$fish_most_recent_dir"
        end

        # https://fishshell.com/docs/current/language.html#syntax-function-autoloading
        __fish_save_most_recent_dir
        __fish_auto_ls

        # fzf, Ctrl+(R|V) Ctrl+Alt+(L|S|P)
        set -gx FZF_DEFAULT_OPTS --bind "alt-k:clear-query"

        # TODO: using home-manager?
        abbr --command git d "diff -b HEAD"
        abbr --command git a "add (git rev-parse --show-toplevel)"
        abbr --command git r "restore --staged --worktree"
        abbr --command git c "commit --amend --reset-author --no-edit"
      '';

      shellAbbrs = {
        ra = "rg --hidden --no-ignore";
        ff = "fd --type f .";
        fa = "fd --hidden --no-ignore";
        up = "upto";
        ze = "zoxide query";
        dh = "dirh";
        dc = "cdh";
        dr = "direnv reload";
      };
    };

    # other deps:
    direnv = {
      enable = true;
      nix-direnv.enable = true;
    };
    fzf.enable = true;
    zoxide.enable = true;
  };
}
