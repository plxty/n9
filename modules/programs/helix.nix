{
  lib,
  n9,
  pkgs,
  ...
}:

{
  options.users = n9.mkAttrsOfSubmoduleOption { } (
    { config, ... }:
    let
      cfg = config.programs.helix;

      kconfig-ts-src = n9.sources.tree-sitter-kconfig;
      kconfig-ts-pkg = pkgs.callPackage (
        { stdenv, ... }:
        stdenv.mkDerivation {
          pname = kconfig-ts-src.repo;
          version = n9.trimRev kconfig-ts-src;
          src = kconfig-ts-src;
          makeFlags = [ "PREFIX=$(out)" ];
        }
      ) { };
    in
    {
      options.programs.helix.enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
      };

      config.environment.packages = lib.mkIf cfg.enable (
        with pkgs;
        [
          nixd
          nixfmt-rfc-style
          bear # should we?
          llvmPackages_21.clang-tools # TODO: follwing latest?
          bash-language-server
          shellcheck
          ruff
          python3Packages.jedi-language-server
          python3Packages.python-lsp-server
        ]
      );

      config.variant.home-manager.programs.helix = lib.mkIf cfg.enable {
        enable = true;
        defaultEditor = true;
        package = (n9.patch pkgs.helix "helix-taste").overrideAttrs {
          # Skip check for our own builds, to speed up building:
          doCheck = false;
        };

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
              m = [
                ":format"
                ":write --format"
              ]; # habits...
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

        # Force some options:
        languages.language-server.clangd = {
          command = "clangd";
          args = [
            "--header-insertion=never" # TODO: Remove when new clangd is used
            # "--path-mappings=/home=/data00/home" # /data00/home /home none defaults,bind 0 0
          ];
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
      };

      # Most LSP or tree-sitter things:
      config.deployment.file = {
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
              "-mpreferred-stack-boundary=*"
              "-fno-var-tracking-assignments"
              "-flive-patching=*"
              "-mrecord-mcount"
              "-mindirect-branch=*"
              "-mindirect-branch-register"
            ];
          };
          Diagnostics = {
            # https://github.com/clangd/clangd/issues/1407
            # https://github.com/clangd/clangd/issues/337
            # Seems won't be fixed soon...
            Suppress = [ "pp_including_mainfile_in_preamble" ];
          };
          Completion = {
            HeaderInsertion = "Never";
          };
        };
      };
    }
  );
}
