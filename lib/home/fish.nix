{ pkgs, ... }: # <- Home Manager `imports = []`

let
  plugin = pkg: { inherit (pkg) name src; };
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
      };

      shellInit = ''
        # https://linux.overshoot.tv/wiki/ls
        set -gx LS_COLORS (string replace -a '05;' "" "$LS_COLORS")

        # FIXME: (no) local:
        fish_add_path "$HOME/.local/bin"
      '';

      interactiveShellInit = ''
        if not set -qu tide_nix_shell_color
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
        end

        # No greetings:
        set fish_greeting

        # Trying if it is useful:
        set -qu fish_most_recent_dir && [ -d "$fish_most_recent_dir" ] && cd "$fish_most_recent_dir"

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
