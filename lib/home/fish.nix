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
          name = "autols";
          src = pkgs.fetchFromGitHub {
            owner = "kpbaks";
            repo = "autols.fish";
            rev = "fe2693e80558550e0d995856332b280eb86fde19";
            hash = "sha256-EPgvY8gozMzai0qeDH2dvB4tVvzVqfEtPewgXH6SPGs=";
          };
        }
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

        # fzf, Ctrl+(R|V) Ctrl+Alt+(L|S|P)
        set -gx FZF_DEFAULT_OPTS --bind "alt-k:clear-query"

        # https://github.com/haslersn/any-nix-shell
        ${pkgs.any-nix-shell}/bin/any-nix-shell fish | source
      '';

      shellAbbrs = {
        hi = "hx .";
        ra = "rg --hidden --no-ignore";
        ff = "fd --type f .";
        up = "upto";
        ze = "zoxide query";
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
