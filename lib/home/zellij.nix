{
  programs = {
    zellij = {
      enable = true;
      settings = {
        simplified_ui = true;
        default_shell = "fish";
        theme = "nord";
        scroll_buffer_size = 99999;
        show_startup_tips = false;
        show_release_notes = false;

        # https://github.com/zellij-org/zellij/blob/main/zellij-utils/assets/config/default.kdl
        # https://github.com/zellij-org/zellij/blob/f3351f4f75dd1dc43f8808235553593bf87e68a0/default-plugins/configuration/src/presets.rs
        # https://github.com/nix-community/home-manager/blob/master/tests/lib/generators/tokdl.nix
        # TODO: Make a Helix like keybindings:
        default_mode = "locked";
        # keybinds = {
        #   _props = {
        #     clear-defaults = true;
        #   };

        #   locked = {
        #     "bind \"Ctrl g\"" = {
        #       SwitchToMode = "Normal";
        #     };
        #   };

        #   normal = {
        #   };
        # };
      };
    };

    bash = {
      enable = true;

      # Make all SSH share one `w` session, for side monitor or else:
      initExtra = ''
        if [[ "$(ps -o comm= -p $$)" == "systemd" && "$SSH_CONNECTION" != "" ]]; then
          exec zellij attach -c w
        fi
      '';
    };

    fish.functions = {
      # run (send) command to a remote zellij session:
      zw = ''
        set -f session $argv[1]
        set -f args $argv[2..-1]

        if test -z "$session"
          echo "zw [session] args..."
          return
        end

        if zellij list-sessions -ns | not grep -q "$session"
          set session w
          set args $argv
        end

        zellij -s "$session" action write-chars "cd $PWD && $args"
        zellij -s "$session" action write 10
      '';
    };
  };
}
