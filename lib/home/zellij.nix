{ lib, ... }:

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
        # https://github.com/nix-community/home-manager/blob/master/tests/lib/generators/tokdl.nix
        "keybinds clear-defaults=true" =
          let
            keys = lib.concatMapAttrs (
              key: actions: {
                "bind \"${key}\"" = actions;
              }
            );
            p = key: value: { ${key} = if value == null then [ ] else value; };
          in
          {
            normal = keys {
              # Default keys:
              "Alt h" = p "MoveFocus" "Left";
              "Alt j" = p "MoveFocus" "Down";
              "Alt k" = p "MoveFocus" "Up";
              "Alt l" = p "MoveFocus" "Right"; # override `ls` shortcut in some shells
              "Alt H" = p "MovePane" "Left";
              "Alt J" = p "MovePane" "Down";
              "Alt K" = p "MovePane" "Up";
              "Alt L" = p "MovePane" "Right";
              "Alt 1" = p "GoToTab" 1;
              "Alt 2" = p "GoToTab" 2;
              "Alt 3" = p "GoToTab" 3;
              "Alt 4" = p "GoToTab" 4;
              "Alt 5" = p "GoToTab" 5;
              "Alt 6" = p "GoToTab" 6;
              "Alt 7" = p "GoToTab" 7;
              "Alt Tab" = p "SwitchFocus" null;

              # Tmux-like prefix (why not alt?):
              "Ctrl g" = p "SwitchToMode" "Locked";
            };

            locked = keys {
              # Escape:
              "Ctrl g" = p "SwitchToMode" "Normal";
              Esc = p "SwitchToMode" "Normal";

              # Session:
              d = p "Detach" null;
              m = p "SwitchToMode" "Normal" // {
                "LaunchOrFocusPlugin \"session-manager\"" = {
                  floating = true;
                  move_to_focused_tab = true;
                };
              };
              c = p "SwitchToMode" "Normal" // {
                "LaunchOrFocusPlugin \"configuration\"" = {
                  floating = true;
                  move_to_focused_tab = true;
                };
              };
              p = p "SwitchToMode" "Normal" // {
                "LaunchOrFocusPlugin \"plugin-manager\"" = {
                  floating = true;
                  move_to_focused_tab = true;
                };
              };

              # To other modes, from default.kdl:
              r = p "SwitchToMode" "Resize";
              w = p "SwitchToMode" "Pane";
              t = p "SwitchToMode" "Tab";
              Space = p "SwitchToMode" "Scroll";
              "/" = p "SwitchToMode" "Search";
              s = p "SwitchToMode" "Session";
            };

            resize = keys {
              # Escape:
              "Ctrl g" = p "SwitchToMode" "Normal";
              Esc = p "SwitchToMode" "Normal";

              # default.kdl:
              h = p "Resize" "Increase Left";
              j = p "Resize" "Increase Down";
              k = p "Resize" "Increase Up";
              l = p "Resize" "Increase Right";
              H = p "Resize" "Decrease Left";
              J = p "Resize" "Decrease Down";
              K = p "Resize" "Decrease Up";
              L = p "Resize" "Decrease Right";
              "=" = p "Resize" "Increase";
              "-" = p "Resize" "Decrease";
            };

            pane = keys {
              # Escape:
              "Ctrl g" = p "SwitchToMode" "Normal";
              Esc = p "SwitchToMode" "Normal";

              # default.kdl:
              n = p "NewPane" null // p "SwitchToMode" "Normal";
              s = p "NewPane" "Down" // p "SwitchToMode" "Normal";
              v = p "NewPane" "Right" // p "SwitchToMode" "Normal";
              q = p "CloseFocus" null // p "SwitchToMode" "Normal";
              z = p "TogglePaneFrames" null // p "SwitchToMode" "Normal";
              Space = p "TogglePaneEmbedOrFloating" null // p "SwitchToMode" "Normal";
              r = p "SwitchToMode" "RenamePane" // p "PaneNameInput" 0;
              p = p "TogglePanePinned" null // p "SwitchToMode" "Normal";
            };
            renamepane = keys {
              "Ctrl g" = p "SwitchToMode" "Normal";
              Esc = p "UndoRenamePane" null // p "SwitchToMode" "Normal";
            };

            tab = keys {
              # Escape:
              "Ctrl g" = p "SwitchToMode" "Normal";
              Esc = p "SwitchToMode" "Normal";

              # default.kdl:
              h = p "GoToPreviousTab" null;
              l = p "GoToNextTab" null;
              n = p "Newtab" null // p "SwitchToMode" "Normal";
              q = p "CloseTab" null // p "SwitchToMode" "Normal";
              s = p "ToggleActiveSyncTab" null // p "SwitchToMode" "Normal";
              b = p "BreakPane" null // p "SwitchToMode" "Normal";
              "]" = p "BreakPaneRight" null // p "SwitchToMode" "Normal";
              "[" = p "BreakPaneLeft" null // p "SwitchToMode" "Normal";
              r = p "SwitchToMode" "RenameTab" // p "TabNameInput" 0;
              Tab = p "ToggleTab" null;
            };
            renametab = keys {
              "Ctrl g" = p "SwitchToMode" "Normal";
              Esc = p "UndoRenameTab" null // p "SwitchToMode" "Normal";
            };

            scroll = keys {
              # Escape:
              "Ctrl g" = p "SwitchToMode" "Normal";
              Esc = p "SwitchToMode" "Normal";

              # default.kdl:
              i = p "EditScrollback" null // p "SwitchToMode" "Normal";
              "/" = p "SwitchToMode" "EnterSearch" // p "SearchInput" 0;
              j = p "ScrollDown" null;
              k = p "ScrollUp" null;
              G = p "ScrollToBottom" null;
              "Ctrl f" = p "PageScrollDown" null;
              "Ctrl b" = p "PageScrollUp" null;
              "Ctrl d" = p "HalfPageScrollDown" null;
              "Ctrl u" = p "HalfPageScrollUp" null;
              f = p "PageScrollDown" null;
              b = p "PageScrollUp" null;
              d = p "HalfPageScrollDown" null;
              u = p "HalfPageScrollUp" null;
            };
            entersearch = keys {
              "Ctrl g" = p "SwitchToMode" "Scroll";
              Esc = p "SwitchToMode" "Scroll";
              Enter = p "SwitchToMode" "Search";
            };

            search = keys {
              # Escape:
              "Ctrl g" = p "ScrollToBottom" null // p "SwitchToMode" "Normal";
              Esc = p "SwitchToMode" "Normal";

              # default.kdl:
              n = p "Search" "down";
              N = p "Search" "up";
              "?" = p "SearchToggleOption" "CaseSensitivity";
              a = p "SearchToggleOption" "Wrap";
              w = p "SearchToggleOption" "WholeWord";
              j = p "ScrollDown" null;
              k = p "ScrollUp" null;
              G = p "ScrollToBottom" null;
              "Ctrl f" = p "PageScrollDown" null;
              "Ctrl b" = p "PageScrollUp" null;
              "Ctrl d" = p "HalfPageScrollDown" null;
              "Ctrl u" = p "HalfPageScrollUp" null;
              f = p "PageScrollDown" null;
              b = p "PageScrollUp" null;
              d = p "HalfPageScrollDown" null;
              u = p "HalfPageScrollUp" null;
            };
          };
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
