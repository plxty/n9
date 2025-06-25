{
  config,
  lib,
  pkgs,
  n9,
  ...
}:

let
  cfg = config.n9.programs.helix;

  kconfig-ts-src = pkgs.fetchFromGitHub {
    owner = "tree-sitter-grammars";
    repo = "tree-sitter-kconfig";
    rev = "9ac99fe4c0c27a35dc6f757cef534c646e944881";
    hash = "sha256-8gZZLGL7giVHQIirjUIfsx3scP1L1VTFIZX7QOyjWvk=";
  };

  kconfig-ts-pkg = pkgs.callPackage (
    { stdenv, ... }:
    stdenv.mkDerivation {
      pname = kconfig-ts-src.repo;
      version = kconfig-ts-src.rev;
      src = kconfig-ts-src;
      makeFlags = [ "PREFIX=$(out)" ];
    }
  ) { };
in
{
  options.n9.programs.helix.enable = lib.mkOption {
    type = lib.types.bool;
    default = true;
  };

  config = lib.mkIf cfg.enable {
    # TODO: To shells.
    home.packages = with pkgs; [
      nixd
      nixfmt-rfc-style
      clang-tools
      bash-language-server
      shellcheck
      ruff
      python3Packages.jedi-language-server
      python3Packages.python-lsp-server
    ];

    programs.helix = {
      enable = true;
      package = n9.patch pkgs.helix "helix-taste";
      defaultEditor = true;

      settings = {
        # Look and feel:
        theme = "papercolor-dark";
        editor = {
          line-number = "relative";
          true-color = true;
          rulers = [
            80
            120
          ];
          auto-format = false;
          color-modes = true;
          cursor-shape = {
            insert = "bar";
          };
          file-picker = {
            hidden = true;
            git-ignore = true;
          };
        };

        # Keys
        keys = {
          normal = {
            G = "goto_last_line"; # or ge
            H = "goto_previous_buffer"; # or gp
            L = "goto_next_buffer"; # or gn
            A-j = [
              "extend_to_line_bounds"
              "delete_selection"
              "paste_after"
            ];
            A-k = [
              "extend_to_line_bounds"
              "delete_selection"
              "move_line_up"
              "paste_before"
            ];
            A-J = [
              "extend_to_line_bounds"
              "yank"
              "paste_after"
            ];
            A-K = [
              "extend_to_line_bounds"
              "yank"
              "paste_before"
            ];
            ";" = "goto_word_definition";
            "#" = "select_references_to_symbol_under_cursor";
            # A-[1-7] is occupied by ptyxis, and C-[1-7] seems not working?
            # https://unix.stackexchange.com/questions/226327/what-does-ctrl4-and-ctrl-do-in-bash
            C-h = "jump_view_left";
            C-j = "jump_view_down";
            C-k = "jump_view_up";
            C-l = "jump_view_right";
          };

          normal.space = {
            F = "file_picker_in_current_buffer_directory";
          };

          normal.g = {
            R = [
              "goto_prev_function_name"
              "goto_reference"
            ];
            ";" = "goto_word_reference";
          };

          normal."'" = {
            s = ":toggle search.smart-case";
            r = ":toggle search.regex";
            c = ":toggle search.case-sensitive";
            w = ":toggle search.whole-word";
            h = [
              ":toggle file-picker.hidden"
              ":toggle file-picker.git-ignore"
            ];
            a = ":toggle soft-wrap.enable";
            p = ":toggle auto-pairs";
            f = ":toggle auto-format";
            t = ":toggle smart-tab.enable";
            # will reset all configs to config-default
            "'" = ":config-reload";
            m = ":format-write";
          };

          normal."," = {
            "," = "collapse_selection";
            ";" = "flip_selections";
            "." = "keep_primary_selection";
            "/" = "remove_primary_selection";
          };

          insert = {
            # Emacs navigator
            C-p = "move_line_up";
            C-n = "move_line_down";
            C-b = "move_char_left";
            C-f = "move_char_right";
            A-b = "move_prev_word_start";
            A-f = "move_next_word_end";
            C-a = "goto_line_start";
            C-e = "goto_line_end_newline";
            # Quick commands
            "A-;" = "command_mode";
            A-x = "command_palette";
            # To keep consistency:
            C-h = "jump_view_left";
            C-j = "jump_view_down";
            C-k = "jump_view_up";
            C-l = "jump_view_right";
          };
        };
      };

      languages.language = [
        {
          name = "c";
          indent = {
            tab-width = 8;
            unit = "\t";
          };
        }
        {
          name = "make";
          indent = {
            tab-width = 8;
            unit = "\t";
          };
        }
        {
          name = "kconfig";
          scope = "source.kconfig";
          file-types = [
            { glob = "Kconfig"; }
            { glob = "Kconfig.*"; }
          ];
          comment-token = "#";
          indent = {
            tab-width = 8;
            unit = "\t";
          };
        }
        {
          name = "nix";
          formatter.command = "nixfmt";
        }
      ];

      languages.language-server = {
        # https://github.com/clangd/clangd/issues/55
        clangd = {
          command = "clangd";
          args = [ "--header-insertion=never" ];
        };
      };
    };

    home.file = {
      ".config/helix/runtime/queries/kconfig".source = "${kconfig-ts-src}/queries";

      ".config/helix/runtime/grammars/kconfig.so".source =
        "${kconfig-ts-pkg}/lib/libtree-sitter-kconfig.so";

      ".config/clangd/config.yaml".source = pkgs.writers.writeYAML "config.yaml" {
        CompileFlags = {
          Add = [ "-ferror-limit=0" ];
          Remove = [
            "-march=*"
            "-mabi=*"
            "-mcpu=*"
            "-fno-allow-store-data-races"
            "-fconserve-stack"
            "--no-sysroot-suffix"
            "-fmin-function-alignment=*"
            "-femit-struct-debug-baseonly"
          ];
        };
        Completion = {
          HeaderInsertion = "Never";
        };
      };
    };
  };
}
