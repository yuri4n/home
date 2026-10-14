{ lib, pkgs, ... }:

let
  inherit (pkgs.stdenv) isDarwin;
  merge = lib.foldl' lib.recursiveUpdate { };
  allTrue = names: lib.genAttrs names (_: true);

  # Settings profiles: overlays on the base settings, switched with ctrl-alt-cmd-p
  # (`settings profile selector: toggle`). Every language works in every profile;
  # a profile only turns on what one stack needs.
  focus = {
    inlay_hints.enabled = true;
    code_lens = "on";
  };

  tsHints =
    let
      hints = {
        parameterNames.enabled = "all";
        parameterTypes.enabled = true;
        variableTypes.enabled = true;
        propertyDeclarationTypes.enabled = true;
        functionLikeReturnTypes.enabled = true;
        enumMemberValues.enabled = true;
      };
    in
    {
      lsp.vtsls.settings = {
        typescript.inlayHints = hints;
        javascript.inlayHints = hints;
      };
    };

  profiles = rec {
    Scala = merge [
      focus
      { lsp.metals.settings.superMethodLensesEnabled = true; }
    ];

    Frontend = merge [
      focus
      tsHints
      {
        theme = {
          light = "One Light"; # Zed has no Cursor Light
          dark = "Anysphere Theme";
        };
        icon_theme = {
          light = "Catppuccin Latte";
          dark = "Catppuccin Mocha";
        };
        buffer_line_height.custom = 1.7;
        terminal.line_height.custom = 1.2;
      }
    ];

    "Scala + Frontend" = merge [
      Scala
      Frontend
    ];

    Elixir = merge [
      focus
      { lsp.elixir-ls.settings.enableTestLenses = true; }
    ];

    Phoenix = merge [
      Elixir
      tsHints
      {
        lsp.tailwindcss-language-server.settings = {
          includeLanguages = {
            elixir = "html";
            heex = "html";
          };
          experimental.classRegex = [
            ''class="([^"]*)"''
            "class='([^']*)'"
          ];
        };
      }
    ];

    Python = merge [
      focus
      { lsp.basedpyright.settings.basedpyright.analysis.typeCheckingMode = "standard"; }
    ];

    Rust = merge [
      focus
      {
        lsp.rust-analyzer.initialization_options.inlayHints = {
          lifetimeElisionHints = {
            enable = "skip_trivial";
            useParameterNames = true;
          };
          closureReturnTypeHints.enable = "always";
        };
      }
    ];

    Go = merge [
      focus
      {
        lsp.gopls.initialization_options = {
          hints = allTrue [
            "assignVariableTypes"
            "compositeLiteralFields"
            "compositeLiteralTypes"
            "constantValues"
            "functionTypeParameters"
            "parameterNames"
            "rangeVariableTypes"
          ];
          codelenses = allTrue [
            "test"
            "generate"
            "tidy"
            "upgrade_dependency"
          ];
        };
      }
    ];

    "C/C++" = focus;

    "C#" = merge [
      focus
      {
        lsp.roslyn.settings."csharp|inlay_hints" = allTrue [
          "dotnet_enable_inlay_hints_for_parameters"
          "csharp_enable_inlay_hints_for_types"
          "csharp_enable_inlay_hints_for_implicit_variable_types"
          "csharp_enable_inlay_hints_for_lambda_parameter_types"
        ];
      }
    ];

    Deno = merge [
      focus
      {
        lsp.deno.settings.deno.enable = true;
        languages = lib.genAttrs [ "JavaScript" "TypeScript" "TSX" ] (_: {
          language_servers = [
            "deno"
            "!typescript-language-server"
            "!vtsls"
            "!eslint"
          ];
          formatter = "language_server";
        });
      }
    ];
  };

  # macOS: file types that open in Zed.
  codeFiles = "c cpp cs css env erl ex exs go graphql h heex hpp hs http js json jsx lua md mjs ml nix py rs sbt sc scala scss sh sql toml ts tsx txt vue yaml yml zsh";
in
{
  programs.zed-editor = {
    enable = true;
    package = if isDarwin then null else pkgs.zed-editor; # macOS: Zed.app updates itself

    extensions = [
      "catppuccin"
      "catppuccin-icons"
      "anysphere-theme"
      # Languages in ~/Developer/{projects,learning}
      "scala"
      "hocon"
      "smithy"
      "elixir"
      "erlang"
      "vue"
      "unocss"
      "emmet"
      "scss"
      "graphql"
      "deno"
      "csharp"
      "haskell"
      "ocaml"
      "neocmake"
      "make"
      "nix"
      "toml"
      "xml"
      "sql"
      "lua"
      "unison"
      "basher"
      "dockerfile"
      "docker-compose"
      "terraform"
      "github-actions"
      # Files and tools
      "env"
      "http"
      "log"
      "mermaid"
      "rainbow-csv"
      "git-firefly"
      "discord-presence"
    ];

    # Zed can still change settings.json; these keys win on every switch.
    userSettings = {
      cli_default_open_behavior = "new_window";
      restore_on_startup = "none";

      theme = {
        light = "Catppuccin Latte";
        dark = "Catppuccin Mocha";
      };
      icon_theme = {
        light = "Catppuccin Mocha";
        dark = "Catppuccin Mocha";
      };
      buffer_font_family = "AnnotationMono Nerd Font";
      buffer_font_fallbacks = [ "MartianMono Nerd Font" ];
      buffer_font_size = 13.7;
      buffer_font_weight = 500;
      buffer_line_height.custom = 1.8;
      buffer_font_features.calt = true;
      ui_font_size = 15;

      vim_mode = true;
      vim.use_system_clipboard = "never";
      tab_size = 2;
      format_on_save = "on";
      autosave.after_delay.milliseconds = 300;
      colorize_brackets = true;
      current_line_highlight = "line";
      sticky_scroll.enabled = true;
      minimap.show = "always";
      indent_guides = {
        coloring = "indent_aware";
        background_coloring = "indent_aware";
      };
      diagnostics.inline.enabled = true;
      tabs = {
        file_icons = true;
        git_status = true;
        show_diagnostics = "all";
      };
      git.inline_blame.show_commit_summary = true;
      edit_predictions.provider = "copilot";
      terminal = {
        font_size = 15.6;
        line_height.custom = 1.0;
        env = {
          # Keep Kiro and Amazon Q out of Zed's terminal.
          CW_NEW_SESSION = "1";
          Q_NEW_SESSION = "1";
        };
      };
      telemetry = {
        diagnostics = false;
        metrics = false;
      };
      file_types = {
        tailwindcss = [ "*.css" ];
        json = [ "*.json" ];
      };
      context_servers.nuxt.url = "https://mcp.nuxt.com/sse";

      languages =
        lib.genAttrs [ "JavaScript" "TypeScript" "TSX" "Vue.js" ] (_: {
          formatter = [ ]; # ESLint fixes the file instead
          code_actions_on_format."source.fixAll.eslint" = true;
        })
        // {
          Markdown = {
            soft_wrap = "editor_width";
            formatter = "prettier";
            show_edit_predictions = false;
          };
          "Plain Text".show_edit_predictions = false;
          JSON.formatter = "prettier";
          JSONC.formatter = "prettier";
          Scala.code_actions_on_format."source.organizeImports" = false;
          "Shell Script".formatter.external = {
            command = "shfmt";
            arguments = [
              "-i"
              "2"
              "--filename"
              "{buffer_path}"
            ];
          };
          Nix.language_servers = [
            "nixd"
            "!nil"
            "..."
          ];
        };

      lsp = {
        metals.settings.inlayHints =
          lib.genAttrs
            [
              "inferredTypes"
              "implicitArguments"
              "implicitConversions"
              "typeParameters"
              "hintsInPatternMatch"
            ]
            (_: {
              enable = true;
            });
        rust-analyzer.initialization_options.check.command = "clippy";
        hls.initialization_options.haskell.formattingProvider = "fourmolu";
        nixd.settings.formatting.command = [ "nixfmt" ];
      };

      profiles = lib.mapAttrs (_: settings: { inherit settings; }) profiles;
    };

    # The same keys as Neovim: https://github.com/yuri4n/nvim/blob/main/CHEATSHEET.md
    userKeymaps = [
      {
        context = "Editor && vim_mode == insert && !menu";
        bindings = {
          "j k" = "vim::NormalBefore";
          ctrl-s = "editor::ShowSignatureHelp";
        };
      }
      {
        context = "vim_mode == normal && !menu";
        bindings = {
          "g r t" = "editor::GoToTypeDefinition";
          "g shift-o" = "outline::Toggle";
          "space f f" = "file_finder::Toggle";
          "space f g" = "pane::DeploySearch";
          "space f b" = "tab_switcher::Toggle";
          "space f s" = "outline::Toggle";
          "space f shift-s" = "project_symbols::Toggle";
          "space f d" = "diagnostics::Deploy";
          "space e" = "project_panel::ToggleFocus";
          "space b d" = "pane::CloseActiveItem";
          "space c f" = "editor::Format";
          "space t h" = "editor::ToggleInlayHints";
          "space g s" = "git::ToggleStaged";
          "space g r" = "git::Restore";
          "space g d" = "editor::ToggleSelectedDiffHunks";
          "space g b" = "git::Blame";
          "space g g" = "git_panel::ToggleFocus";
        };
      }
      {
        context = "Editor";
        bindings = {
          ctrl-shift-h = "editor::ToggleInlayHints"; # off by default; profiles turn them on
          "shift-alt-\\" = "editor::ShowEditPrediction";
        };
      }
      {
        context = "Terminal";
        # A newline in Claude Code and other TUIs.
        bindings.shift-enter = [
          "terminal::SendText"
          (builtins.fromJSON ''"\u001b\r"'')
        ];
      }
      {
        context = "Workspace";
        bindings = {
          ctrl-shift-cmd-i = "agent::ToggleFocus";
          shift-alt-cmd-i = "agent::NewThread";
        };
      }
    ];
  };

  home.shellAliases = lib.mkIf (!isDarwin) { zed = "zeditor"; };

  home.activation.zedOpensCode = lib.mkIf isDarwin (
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      for ext in ${codeFiles}; do
        run ${pkgs.duti}/bin/duti -s dev.zed.Zed ".$ext" all || true
      done
    ''
  );
}
