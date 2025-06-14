# Generated via dconf2nix: https://github.com/gvolpe/dconf2nix
{ lib, ... }:

with lib.hm.gvariant;

{
  dconf.settings = {
    "desktop/ibus/panel" = {
      show-icon-on-systray = true;
    };

    "org/gnome/Ptyxis" = {
      audible-bell = false;
      cursor-shape = "underline";
      default-profile-uuid = "8b11dd3e6b265e6a5fd6ce60678873ea";
      font-name = "JetBrains Mono 9";
      profile-uuids = [ "8b11dd3e6b265e6a5fd6ce60678873ea" ];
      restore-session = true;
      restore-window-size = true;
      text-blink-mode = "never";
      use-system-font = false;
    };

    "org/gnome/Ptyxis/Profiles/8b11dd3e6b265e6a5fd6ce60678873ea" = {
      bold-is-bright = false;
      cjk-ambiguous-width = "narrow";
      custom-command = "fish";
      exit-action = "close";
      login-shell = true;
      palette = "Vs Code";
      preserve-directory = "never";
      scrollback-lines = 99999;
      use-custom-command = true;
    };

    "org/gnome/Ptyxis/Shortcuts" = {
      move-next-tab = "<Alt>l";
      move-previous-tab = "<Alt>h";
      move-tab-left = "<Shift><Alt>h";
      move-tab-right = "<Shift><Alt>l";
    };

    "org/gnome/desktop/input-sources" = {
      per-window = true;
      sources = [ (mkTuple [ "xkb" "us" ]) (mkTuple [ "ibus" "rime" ]) ];
    };

    "org/gnome/desktop/interface" = {
      accent-color = "slate";
      color-scheme = "prefer-dark";
      document-font-name = "Noto Sans CJK SC 11 @wght=400";
      enable-hot-corners = false;
      font-antialiasing = "rgba";
      font-hinting = "slight";
      font-name = "Noto Sans CJK SC 11 @wght=400";
      monospace-font-name = "Noto Sans Mono CJK SC 10";
      show-battery-percentage = true;
      toolkit-accessibility = false;
    };

    "org/gnome/desktop/peripherals/mouse" = {
      natural-scroll = false;
    };

    "org/gnome/desktop/peripherals/touchpad" = {
      edge-scrolling-enabled = false;
    };

    "org/gnome/desktop/session" = {
      idle-delay = mkUint32 900;
    };

    "org/gnome/desktop/wm/keybindings" = {
      begin-move = [];
      begin-resize = [];
      close = [];
      cycle-group = [];
      cycle-group-backward = [];
      cycle-panels = [];
      cycle-panels-backward = [];
      cycle-windows = [];
      cycle-windows-backward = [];
      maximize = [];
      minimize = [];
      move-to-monitor-down = [];
      move-to-monitor-left = [];
      move-to-monitor-right = [];
      move-to-monitor-up = [];
      move-to-workspace-1 = [ "<Shift><Super>1" ];
      move-to-workspace-2 = [ "<Shift><Super>2" ];
      move-to-workspace-3 = [ "<Shift><Super>3" ];
      move-to-workspace-4 = [ "<Shift><Super>4" ];
      move-to-workspace-5 = [ "<Shift><Super>5" ];
      move-to-workspace-6 = [ "<Shift><Super>6" ];
      move-to-workspace-7 = [ "<Shift><Super>7" ];
      move-to-workspace-8 = [ "<Shift><Super>8" ];
      move-to-workspace-9 = [ "<Shift><Super>9" ];
      move-to-workspace-down = [ "<Control><Shift><Alt>Down" ];
      move-to-workspace-last = [];
      move-to-workspace-left = [];
      move-to-workspace-right = [];
      move-to-workspace-up = [ "<Control><Shift><Alt>Up" ];
      panel-run-dialog = [];
      switch-applications = [];
      switch-applications-backward = [];
      switch-group = [];
      switch-group-backward = [];
      switch-panels = [];
      switch-panels-backward = [];
      switch-to-workspace-1 = [ "<Super>1" ];
      switch-to-workspace-2 = [ "<Super>2" ];
      switch-to-workspace-3 = [ "<Super>3" ];
      switch-to-workspace-4 = [ "<Super>4" ];
      switch-to-workspace-5 = [ "<Super>5" ];
      switch-to-workspace-6 = [ "<Super>6" ];
      switch-to-workspace-7 = [ "<Super>7" ];
      switch-to-workspace-8 = [ "<Super>8" ];
      switch-to-workspace-9 = [ "<Super>9" ];
      switch-to-workspace-last = [];
      switch-to-workspace-left = [];
      switch-to-workspace-right = [];
      toggle-maximized = [];
      unmaximize = [];
    };

    "org/gnome/desktop/wm/preferences" = {
      mouse-button-modifier = "disabled";
      workspace-names = [ "Workspace 1" "Workspace 2" "Workspace 3" "Workspace 4" ];
    };

    "org/gnome/gedit/plugins" = {
      active-plugins = [ "spell" "sort" "textsize" "docinfo" "quickhighlight" "filebrowser" ];
    };

    "org/gnome/gedit/preferences/editor" = {
      display-line-numbers = true;
      display-right-margin = true;
      editor-font = "Noto Sans Mono CJK SC 10";
      style-scheme-for-dark-theme-variant = "oblivion";
      use-default-font = false;
      wrap-last-split-mode = "word";
    };

    "org/gnome/gedit/preferences/ui" = {
      statusbar-visible = true;
      theme-variant = "dark";
    };

    "org/gnome/mutter" = {
      attach-modal-dialogs = false;
      edge-tiling = false;
      experimental-features = [ "scale-monitor-framebuffer" ];
      workspaces-only-on-primary = false;
    };

    "org/gnome/mutter/keybindings" = {
      cancel-input-capture = [ "<Super><Shift>Escape" ];
      switch-monitor = [];
      toggle-tiled-left = [];
      toggle-tiled-right = [];
    };

    "org/gnome/mutter/wayland/keybindings" = {
      restore-shortcuts = [];
    };

    "org/gnome/settings-daemon/plugins/color" = {
      night-light-schedule-automatic = false;
    };

    "org/gnome/settings-daemon/plugins/media-keys" = {
      custom-keybindings = [];
      email = [];
      help = [];
      home = [];
      logout = [];
      magnifier = [];
      magnifier-zoom-in = [];
      magnifier-zoom-out = [];
      rotate-video-lock-static = [];
      screenreader = [];
      screensaver = [ "<Super>Pause" ];
      volume-down = [ "AudioLowerVolume" ];
      volume-mute = [ "AudioMute" ];
      volume-up = [ "AudioRaiseVolume" ];
      www = [];
    };

    "org/gnome/settings-daemon/plugins/power" = {
      power-button-action = "interactive";
      sleep-inactive-ac-type = "nothing";
    };

    "org/gnome/shell" = {
      disable-user-extensions = false;
      favorite-apps = [];
    };

    "org/gnome/shell/extensions/customize-ibus" = {
      candidate-popup-animation = mkUint32 2;
      candidate-scroll-mode = mkUint32 1;
      enable-auto-switch = true;
      input-indicator-hide-time = mkUint32 2;
      input-indicator-not-on-single-ime = true;
      input-indicator-only-on-toggle = false;
      input-indicator-only-use-ascii = false;
      input-indicator-right-close = true;
      input-indicator-use-scroll = false;
      menu-ibus-restart = true;
      unkown-ascii-state = mkUint32 1;
      use-candidate-box-right-click = false;
      use-candidate-scroll = false;
      use-candidate-still = false;
      use-popup-animation = false;
      use-tray = true;
    };

    "org/gnome/shell/extensions/dash-to-dock" = {
      apply-custom-theme = true;
      background-opacity = 0.8;
      click-action = "previews";
      custom-background-color = false;
      custom-theme-shrink = false;
      dash-max-icon-size = 48;
      dock-position = "BOTTOM";
      extend-height = false;
      height-fraction = 0.9;
      hot-keys = false;
      icon-size-fixed = false;
      intellihide-mode = "FOCUS_APPLICATION_WINDOWS";
      isolate-monitors = false;
      isolate-workspaces = false;
      middle-click-action = "launch";
      multi-monitor = false;
      running-indicator-style = "DASHES";
      scroll-action = "switch-workspace";
      shift-click-action = "minimize";
      shift-middle-click-action = "launch";
      show-apps-always-in-the-edge = true;
      show-mounts = false;
      show-mounts-only-mounted = true;
      show-show-apps-button = true;
      show-trash = false;
      show-windows-preview = true;
      transparency-mode = "DYNAMIC";
      workspace-agnostic-urgent-windows = true;
    };

    "org/gnome/shell/extensions/display-brightness-ddcutil" = {
      button-location = 1;
      ddcutil-queue-ms = 130.0;
      ddcutil-sleep-multiplier = 40.0;
      decrease-brightness-shortcut = [ "XF86MonBrightnessDown" ];
      hide-system-indicator = true;
      increase-brightness-shortcut = [ "XF86MonBrightnessUp" ];
      only-all-slider = true;
      position-system-menu = 3.0;
      show-all-slider = false;
      show-internal-slider = false;
      show-value-label = true;
      step-change-keyboard = 5.0;
    };

    "org/gnome/shell/extensions/focus" = {
      inactive-opacity = mkUint32 95;
      is-background-blur = false;
      is-desaturate-enabled = false;
      special-focus-opacity = mkUint32 95;
    };

    "org/gnome/shell/extensions/paperwm" = {
      animation-time = 0.15;
      cycle-height-steps = [ 0.38195 0.5 0.61804 ];
      cycle-width-steps = [ 0.38195 0.5 0.61804 ];
      default-focus-mode = 0;
      disable-scratch-in-overview = false;
      drag-drift-speed = 3;
      drift-speed = 3;
      edge-preview-enable = false;
      edge-preview-scale = 0.5;
      gesture-enabled = false;
      horizontal-margin = 7;
      minimap-scale = 0.0;
      only-scratch-in-overview = false;
      overview-ensure-viewport-animation = 1;
      selection-border-radius-bottom = 0;
      selection-border-radius-top = 0;
      selection-border-size = 7;
      show-window-position-bar = true;
      show-workspace-indicator = false;
      use-default-background = true;
      vertical-margin = 7;
      vertical-margin-bottom = 7;
      window-gap = 21;
    };

    "org/gnome/shell/extensions/paperwm/keybindings" = {
      barf-out = [ "<Super>period" ];
      barf-out-active = [ "<Shift><Super>greater" ];
      center-horizontally = [ "" ];
      center-vertically = [ "" ];
      cycle-height = [ "<Super>t" ];
      cycle-height-backwards = [ "<Shift><Super>t" ];
      cycle-width-backwards = [ "<Shift><Super>r" ];
      drift-left = [ "<Super>bracketleft" ];
      drift-right = [ "<Super>bracketright" ];
      live-alt-tab = [ "<Super>Tab" ];
      live-alt-tab-backward = [ "<Shift><Super>Tab" ];
      live-alt-tab-scratch = [ "" ];
      live-alt-tab-scratch-backward = [ "" ];
      move-down = [ "<Shift><Super>j" ];
      move-down-workspace = [ "<Shift><Super>d" ];
      move-left = [ "<Shift><Super>h" ];
      move-monitor-above = [ "<Shift><Super>p" ];
      move-monitor-below = [ "<Shift><Super>n" ];
      move-monitor-left = [ "<Shift><Super>s" ];
      move-monitor-right = [ "<Shift><Super>g" ];
      move-previous-workspace = [ "" ];
      move-previous-workspace-backward = [ "" ];
      move-right = [ "<Shift><Super>l" ];
      move-space-monitor-above = [ "" ];
      move-space-monitor-below = [ "" ];
      move-space-monitor-left = [ "" ];
      move-space-monitor-right = [ "" ];
      move-up = [ "<Shift><Super>k" ];
      move-up-workspace = [ "<Shift><Super>f" ];
      new-window = [ "<Super>Return" ];
      paper-toggle-fullscreen = [ "<Shift><Super>m" ];
      previous-workspace = [ "<Super>q" ];
      previous-workspace-backward = [ "<Shift><Super>q" ];
      slurp-in = [ "<Super>comma" ];
      swap-monitor-above = [ "" ];
      swap-monitor-below = [ "" ];
      swap-monitor-left = [ "" ];
      swap-monitor-right = [ "" ];
      switch-down = [ "<Super>j" ];
      switch-down-workspace = [ "<Super>d" ];
      switch-down-workspace-from-all-monitors = [ "" ];
      switch-first = [ "<Super>a" ];
      switch-focus-mode = [ "<Super>c" ];
      switch-last = [ "<Super>e" ];
      switch-left = [ "<Super>h" ];
      switch-monitor-above = [ "<Super>p" ];
      switch-monitor-below = [ "<Super>n" ];
      switch-monitor-left = [ "<Super>s" ];
      switch-monitor-right = [ "<Super>g" ];
      switch-next = [ "" ];
      switch-next-loop = [ "<Super>i" ];
      switch-open-window-position = [ "<Super>w" ];
      switch-previous = [ "" ];
      switch-previous-loop = [ "<Super>o" ];
      switch-right = [ "<Super>l" ];
      switch-up = [ "<Super>k" ];
      switch-up-workspace = [ "<Super>f" ];
      switch-up-workspace-from-all-monitors = [ "" ];
      take-window = [ "<Super>v" ];
      toggle-maximize-width = [ "<Super>m" ];
      toggle-scratch = [ "" ];
      toggle-scratch-layer = [ "<Shift><Super>z" ];
      toggle-scratch-window = [ "<Super>z" ];
      toggle-top-and-position-bar = [ "<Super>b" ];
    };

    "org/gnome/shell/extensions/switcher" = {
      activate-immediately = false;
      fade-enable = true;
      font-size = mkUint32 16;
      icon-size = mkUint32 16;
      matching = mkUint32 0;
      on-active-display = true;
      only-current-workspace = false;
      show-original-names = true;
      show-switcher = [ "<Super>x" ];
      workspace-indicator = false;
    };

    "org/gnome/shell/extensions/trayIconsReloaded" = {
      applications = "[]";
      icon-brightness = 0;
      icon-contrast = 0;
      icon-saturation = 0;
      tray-position = "right";
    };

    "org/gnome/shell/keybindings" = {
      focus-active-notification = [];
      shift-overview-down = [ "<Super><Alt>Down" ];
      shift-overview-up = [ "<Super><Alt>Up" ];
      show-screen-recording-ui = [];
      switch-to-application-1 = [];
      switch-to-application-2 = [];
      switch-to-application-3 = [];
      switch-to-application-4 = [];
      toggle-application-view = [];
      toggle-message-tray = [];
      toggle-quick-settings = [];
    };

  };
}
