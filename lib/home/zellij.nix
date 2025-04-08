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
        session_serialization = false;

        # https://github.com/zellij-org/zellij/blob/main/zellij-utils/assets/config/default.kdl
        # https://github.com/nix-community/home-manager/blob/master/tests/lib/generators/tokdl.nix
        default_mode = "locked";
        "keybinds clear-defaults=true" =
          let
            keys = lib.concatMapAttrs (
              key: actions: {
                "bind \"${key}\"" = actions;
              }
            );
            p = key: value: { ${key} = value; };
          in
          {
            locked = keys {
              # Default keys, [hjklHJKL1234567]:
              "Alt h" = p "GoToPreviousTab" [ ];
              "Alt l" = p "GoToNextTab" [ ]; # override `ls` shortcut in some shells
              "Alt H" = p "MoveTab" "Left";
              "Alt L" = p "MoveTab" "Right";
              "Alt 1" = p "GoToTab" 1;
              "Alt 2" = p "GoToTab" 2;
              "Alt 3" = p "GoToTab" 3;
              "Alt 4" = p "GoToTab" 4;
              "Alt 5" = p "GoToTab" 5;
              "Alt 6" = p "GoToTab" 6;
              "Alt 7" = p "GoToTab" 7;

              # Tmux-like prefix (why not alt?):
              "Ctrl g" = p "SwitchToMode" "Normal";
            };

            "shared_except \"locked\"" = keys {
              "Ctrl g" = p "SwitchToMode" "Locked";
              Esc = p "SwitchToMode" "Locked";
            };

            normal = keys {
              # Session [dmcp]:
              d = p "Detach" [ ];
              m = p "SwitchToMode" "Locked" // {
                "LaunchOrFocusPlugin \"session-manager\"" = {
                  floating = true;
                  move_to_focused_tab = true;
                };
              };
              c = p "SwitchToMode" "Locked" // {
                "LaunchOrFocusPlugin \"configuration\"" = {
                  floating = true;
                  move_to_focused_tab = true;
                };
              };
              p = p "SwitchToMode" "Locked" // {
                "LaunchOrFocusPlugin \"plugin-manager\"" = {
                  floating = true;
                  move_to_focused_tab = true;
                };
              };

              # Pane [svqhjklHJKL]
              s = p "NewPane" "Down" // p "SwitchToMode" "Locked";
              v = p "NewPane" "Right" // p "SwitchToMode" "Locked";
              q = p "CloseFocus" [ ] // p "SwitchToMode" "Locked";
              h = p "MoveFocus" "Left" // p "SwitchToMode" "Locked";
              j = p "MoveFocus" "Down" // p "SwitchToMode" "Locked";
              k = p "MoveFocus" "Up" // p "SwitchToMode" "Locked";
              l = p "MoveFocus" "Right" // p "SwitchToMode" "Locked";
              H = p "MovePane" "Left" // p "SwitchToMode" "Locked";
              J = p "MovePane" "Down" // p "SwitchToMode" "Locked";
              K = p "MovePane" "Up" // p "SwitchToMode" "Locked";
              L = p "MovePane" "Right" // p "SwitchToMode" "Locked";

              # Tab, some terminals occupied Alt-<N>, [n1234567]
              n = p "NewTab" [ ] // p "SwitchToMode" "Locked";
              "1" = p "GoToTab" 1 // p "SwitchToMode" "Locked";
              "2" = p "GoToTab" 2 // p "SwitchToMode" "Locked";
              "3" = p "GoToTab" 3 // p "SwitchToMode" "Locked";
              "4" = p "GoToTab" 4 // p "SwitchToMode" "Locked";
              "5" = p "GoToTab" 5 // p "SwitchToMode" "Locked";
              "6" = p "GoToTab" 6 // p "SwitchToMode" "Locked";
              "7" = p "GoToTab" 7 // p "SwitchToMode" "Locked";

              # To other modes, from default.kdl [rwt /]:
              r = p "SwitchToMode" "Resize";
              w = p "SwitchToMode" "Pane";
              t = p "SwitchToMode" "Tab";
              Space = p "SwitchToMode" "Scroll";
              "/" = p "SwitchToMode" "EnterSearch" // p "SearchInput" 0;
            };

            resize = keys {
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
              n = p "NewPane" [ ] // p "SwitchToMode" "Locked";
              z = p "TogglePaneFrames" [ ] // p "SwitchToMode" "Locked";
              Space = p "TogglePaneEmbedOrFloating" [ ] // p "SwitchToMode" "Locked";
              r = p "SwitchToMode" "RenamePane" // p "PaneNameInput" 0;
              p = p "TogglePanePinned" [ ] // p "SwitchToMode" "Locked";
            };
            renamepane = keys {
              # Override:
              Esc = p "UndoRenamePane" [ ] // p "SwitchToMode" "Locked";
            };

            tab = keys {
              h = p "GoToPreviousTab" [ ];
              l = p "GoToNextTab" [ ];
              q = p "CloseTab" [ ] // p "SwitchToMode" "Locked";
              s = p "ToggleActiveSyncTab" [ ] // p "SwitchToMode" "Locked";
              b = p "BreakPane" [ ] // p "SwitchToMode" "Locked";
              "]" = p "BreakPaneRight" [ ] // p "SwitchToMode" "Locked";
              "[" = p "BreakPaneLeft" [ ] // p "SwitchToMode" "Locked";
              r = p "SwitchToMode" "RenameTab" // p "TabNameInput" 0;
              Tab = p "ToggleTab" [ ];
            };
            renametab = keys {
              # Override:
              Esc = p "UndoRenameTab" [ ] // p "SwitchToMode" "Locked";
            };

            scroll = keys {
              i = p "EditScrollback" [ ] // p "SwitchToMode" "Locked";
              "/" = p "SwitchToMode" "EnterSearch" // p "SearchInput" 0;
            };
            entersearch = keys {
              # Override:
              "Ctrl g" = p "SwitchToMode" "Scroll";
              Esc = p "SwitchToMode" "Scroll";
              Enter = p "SwitchToMode" "Search";
            };

            search = keys {
              # Override:
              "Ctrl g" = p "ScrollToBottom" [ ] // p "SwitchToMode" "Locked";

              # default.kdl:
              n = p "Search" "down";
              N = p "Search" "up";
              "?" = p "SearchToggleOption" "CaseSensitivity";
              a = p "SearchToggleOption" "Wrap";
              w = p "SearchToggleOption" "WholeWord";
            };

            "shared_among \"scroll\" \"search\"" = keys {
              j = p "ScrollDown" [ ];
              k = p "ScrollUp" [ ];
              G = p "ScrollToBottom" [ ];
              "Ctrl f" = p "PageScrollDown" [ ];
              "Ctrl b" = p "PageScrollUp" [ ];
              "Ctrl d" = p "HalfPageScrollDown" [ ];
              "Ctrl u" = p "HalfPageScrollUp" [ ];
              f = p "PageScrollDown" [ ];
              b = p "PageScrollUp" [ ];
              d = p "HalfPageScrollDown" [ ];
              u = p "HalfPageScrollUp" [ ];
            };
          };
      };
    };

    bash = {
      enable = true;

      # Make all SSH share one `w` session, for side monitor or else:
      initExtra = ''
        if [[ "$(ps -o comm= -p $PPID)" == "sshd-session" && "$SSH_CONNECTION" != "" ]]; then
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
