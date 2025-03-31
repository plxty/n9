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
              "Alt Tab" = p "SwitchFocus" [ ];

              # Tmux-like prefix (why not alt?):
              "Ctrl g" = p "SwitchToMode" "Normal";
            };

            # Escape:
            "shared_except \"locked\"" = keys {
              "Ctrl g" = p "SwitchToMode" "Locked";
              Esc = p "SwitchToMode" "Locked";
            };

            normal = keys {
              # Session:
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

              # Pane
              s = p "NewPane" "Down" // p "SwitchToMode" "Locked";
              v = p "NewPane" "Right" // p "SwitchToMode" "Locked";
              q = p "CloseFocus" [ ] // p "SwitchToMode" "Locked";

              # Tab
              n = p "NewTab" [ ] // p "SwitchToMode" "Locked";

              # To other modes, from default.kdl:
              r = p "SwitchToMode" "Resize";
              w = p "SwitchToMode" "Pane";
              t = p "SwitchToMode" "Tab";
              Space = p "SwitchToMode" "Scroll";
              "/" = p "SwitchToMode" "Search";
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
              h = p "GoToPreviousTab" [ ] // p "SwitchToMode" "Locked";
              l = p "GoToNextTab" [ ] // p "SwitchToMode" "Locked";
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
