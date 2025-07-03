#!/usr/bin/env cached-nix-shell
#!nix-shell -i python3 -p python3

from configparser import ConfigParser
from typing import List
from io import StringIO
from fnmatch import fnmatch
import subprocess
import sys


# May need to check the excluding periodically?
EXCLUDIND = [
    (
        "ca/desrt/dconf-editor",
        [
            "saved-pathbar-path",  # '/org/gnome/mutter/wayland/'
            "saved-view",  # '/org/gnome/mutter/'
            "window-height",  # 779
            "window-is-maximized",  # false
            "window-width",  # 451
        ],
    ),
    (
        "org/gnome/Extensions",
        [
            "window-height",  # 1712
            "window-maximized",  # false
            "window-width",  # 963
        ],
    ),
    ("org/gnome/Ptyxis", ["window-size"]),
    (
        "org/gnome/boxes",
        [
            "first-run",  # false
            "view",  # 'list-view'
            "window-maximized",  # false
            "window-position",  # [26, 23]
            "window-size",  # [1250, 1368]
        ],
    ),
    (
        "com/gitee/gmg137/NeteaseCloudMusicGtk4",
        ["cache-clear-flag", "music-rate", "volume"],
    ),
    # TODO: Make dconf remove some entries?
    ("org/gnome/Ptyxis/Profiles/e76c429b687c3cf0ba8a89d367b71beb", None),
    ("org/gnome/control-center", ["last-panel", "window-state"]),
    ("org/gnome/desktop/app-folders", ["folder-children"]),
    (
        "org/gnome/desktop/app-folders/folders/*",
        [
            "apps",  # ['org.freedesktop.GnomeAbrt.desktop', 'nm-connection-editor.desktop', 'org.gnome.baobab.desktop', 'org.gnome.Connections.desktop', 'org.gnome.DejaDup.desktop', 'org.gnome.DiskUtility.desktop', 'org.gnome.Evince.desktop', 'org.gnome.FileRoller.desktop', 'org.gnome.font-viewer.desktop', 'org.gnome.Loupe.desktop', 'org.gnome.seahorse.Application.desktop', 'org.gnome.tweaks.desktop', 'org.gnome.Usage.desktop']
            "categories",  # ['X-GNOME-Utilities']
            "name",  # 'X-GNOME-Utilities.directory'
            "translate",  # true
        ],
    ),
    (
        "org/gnome/desktop/background",
        [
            "color-shading-type",  # 'solid'
            "picture-options",  # 'zoom'
            "picture-uri",  # 'file:///run/current-system/sw/share/backgrounds/gnome/pixels-l.jxl'
            "picture-uri-dark",  # 'file:///run/current-system/sw/share/backgrounds/gnome/pixels-d.jxl'
            "primary-color",  # '#967864'
            "secondary-color",  # '#000000'
        ],
    ),
    (
        "org/gnome/desktop/input-sources",
        [
            "mru-sources",
            "xkb-options",
        ],
    ),
    ("org/gnome/desktop/notifications", ["application-children"]),
    ("org/gnome/desktop/notifications/application/*", ["application-id"]),
    ("org/gnome/desktop/peripherals/mouse", ["speed"]),
    ("org/gnome/desktop/peripherals/touchpad", ["two-finger-scrolling-enabled"]),
    ("org/gnome/desktop/peripherals/keyboard", ["numlock-state"]),
    (
        "org/gnome/desktop/screensaver",
        [
            "color-shading-type",  # 'solid'
            "picture-options",  # 'zoom'
            "picture-uri",  # 'file:///run/current-system/sw/share/backgrounds/gnome/pixels-l.jxl'
            "primary-color",  # '#967864'
            "secondary-color",  # '#000000'
        ],
    ),
    ("org/gnome/desktop/search-providers", ["sort-order"]),
    ("org/gnome/evolution-data-server", ["migrated"]),
    (
        "org/gnome/gedit/state/window",
        [
            "bottom-panel-size",  # 140
            "height",  # 627
            "maximized",  # false
            "side-panel-active-page",  # 'GeditWindowDocumentsPanel'
            "side-panel-size",  # 200
            "width",  # 1250
        ],
    ),
    ("org/gnome/gedit/state/file-chooser", ["open-recent"]),
    (
        "org/gnome/nautilus/preferences",
        [
            "default-folder-viewer",  # 'icon-view'
            "migrated-gtk-settings",  # true
            "search-filter-time-type",  # 'last_modified'
        ],
    ),
    (
        "org/gnome/nautilus/window-state",
        [
            "initial-size",  # (2560, 1408)
            "initial-size-file-chooser",  # (890, 550)
            "maximized",  # false
        ],
    ),
    ("org/gnome/nm-applet/eap/*", ["ignore-ca-cert", "ignore-phase2-ca-cert"]),
    ("org/gnome/portal/filechooser/*", ["last-folder-path"]),
    (
        "org/gnome/shell",
        [
            "command-history",  # ['r']
            "enabled-extensions",
            "disabled-extensions",  # ['native-window-placement@gnome-shell-extensions.gcampax.github.com', 'places-menu@gnome-shell-extensions.gcampax.github.com', 'drive-menu@gnome-shell-extensions.gcampax.github.com', 'screenshot-window-sizer@gnome-shell-extensions.gcampax.github.com', 'status-icons@gnome-shell-extensions.gcampax.github.com', 'system-monitor@gnome-shell-extensions.gcampax.github.com', 'window-list@gnome-shell-extensions.gcampax.github.com', 'windowsNavigator@gnome-shell-extensions.gcampax.github.com', 'workspace-indicator@gnome-shell-extensions.gcampax.github.com']
            "last-selected-power-profile",  # 'performance'
            "welcome-dialog-last-shown-version",  # '47.2'
        ],
    ),
    ("org/gnome/shell/extensions/customize-ibus", ["input-mode-list"]),
    ("org/gnome/shell/extensions/pop-shell", None),
    ("org/gnome/shell/extensions/display-brightness-ddcutil", ["ddcutil-binary-path"]),
    ("org/gnome/shell/extensions/switcher", ["launcher-stats"]),
    (
        "org/gnome/shell/extensions/paperwm",
        [
            "last-used-display-server",
            "open-window-position",
            "restore-attach-modal-dialogs",
            "restore-edge-tiling",
            "restore-keybinds",
            "restore-workspaces-only-on-primary",
        ],
    ),
    ("org/gnome/shell/extensions/paperwm/workspaces", ["list"]),
    (
        "org/gnome/shell/extensions/paperwm/workspaces/*",
        [
            "index",
            "show-position-bar",
            "show-top-bar",
        ],
    ),
    (
        "org/gnome/shell/extensions/dash-to-dock",
        ["preferred-monitor", "preferred-monitor-by-connector"],
    ),
    ("org/gnome/tweaks", ["show-extensions-notice"]),
    ("org/gtk/gtk4/settings/file-chooser", ["show-hidden"]),
    (
        "org/gtk/settings/file-chooser",
        [
            "date-format",  # 'regular'
            "location-mode",  # 'path-bar'
            "show-hidden",  # false
            "show-size-column",  # true
            "show-type-column",  # true
            "sidebar-width",  # 148
            "sort-column",  # 'name'
            "sort-directories-first",  # false
            "sort-order",  # 'ascending'
            "type-format",  # 'category'
            "window-position",  # (26, 23)
            "window-size",  # (1203, 902)
        ],
    ),
    (
        "org/gnome/file-roller/listing",
        [
            "list-mode",  # 'as-folder'
            "name-column-width",  # 253
            "show-path",  # false
            "sort-method",  # 'name'
            "sort-type",  # 'ascending'
        ],
    ),
    (
        "org/gnome/file-roller/ui",
        [
            "sidebar-width",  # 200
            "window-height",  # 1394
            "window-width",  # 600
        ],
    ),
    (
        "system/proxy",
        [
            "mode",  # 'manual'
        ],
    ),
    (
        "system/proxy/http",
        [
            "host",  # '127.0.0.1'
            "port",  # 7890
        ],
    ),
    (
        "system/proxy/https",
        [
            "host",  # '127.0.0.1'
            "port",  # 7890
        ],
    ),
]


def main(args: List[str]):
    dconf = subprocess.check_output(["dconf", "dump", "/"])

    config = ConfigParser()
    config.read_string(dconf.decode("ascii"))

    # Filter them out:
    for section in config.sections():
        for ex_section, ex_options in EXCLUDIND:
            if not fnmatch(section, ex_section):
                continue

            if ex_options is not None:
                for option in ex_options:
                    config.remove_option(section, option)
                if len(config.options(section)) == 0:
                    config.remove_section(section)
            else:
                config.remove_section(section)

    # Print python format:
    for section in config.sections():
        print(f'("{section}", [')
        for option in config.options(section):
            print(f'    "{option}",  # {config.get(section, option)}')
        print("]),")

    # Stores it, https://stackoverflow.com/a/20568726
    with StringIO() as pipe, open("dconf-gnome.nix", "w") as output:
        config.write(pipe, space_around_delimiters=False)
        subprocess.Popen(
            ["dconf2nix"], stdin=subprocess.PIPE, stdout=output
        ).communicate(pipe.getvalue().encode("ascii"))

    return 0


if __name__ == "__main__":
    exit(main(sys.argv[1:]))
