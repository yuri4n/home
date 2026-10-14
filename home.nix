{
  config,
  lib,
  pkgs,
  user,
  ...
}:

let
  inherit (pkgs.stdenv) isDarwin;
  home = config.home.homeDirectory;
  repo = "${home}/.config/home-manager"; # where this flake is cloned
  appSupport = "${home}/Library/Application Support";

  # Kiro CLI (macOS) installs its own shell hooks. Source them when present.
  kiro =
    hook:
    lib.optionalString isDarwin ''
      [[ -f "${appSupport}/kiro-cli/shell/${hook}" ]] && builtin source "${appSupport}/kiro-cli/shell/${hook}"
    '';
in
{
  home = {
    username = user;
    homeDirectory = if isDarwin then "/Users/${user}" else "/home/${user}";
    stateVersion = "26.05";

    packages =
      with pkgs;
      [
        neovim
        tmux
        wget
        ripgrep
        fd
        jq
        cmake
        automake
        vips
        kubectl
        shellcheck
        shfmt
        nixfmt
        tree-sitter
        nerd-fonts.martian-mono

        # Language servers for Neovim. Zed also uses them when they are on PATH.
        # Toolchain-bound servers come from mise (ElixirLS, rust-analyzer) or GHCup (HLS).
        basedpyright
        bash-language-server
        clang-tools
        gopls
        lua-language-server
        metals
        nixd
        ruff
        tailwindcss-language-server
        vscode-langservers-extracted
        vtsls
        vue-language-server
        yaml-language-server
      ]
      ++ lib.optionals isDarwin [ duti ]
      ++ lib.optionals (!isDarwin) [ gnupg ]; # macOS keeps its own GnuPG install

    sessionVariables = {
      EDITOR = "nvim";
      GOPATH = "${home}/${if isDarwin then "Library/Go" else "go"}";
      # Neovim gives vtsls Vue's TypeScript plugin from this package.
      VUE_LANGUAGE_SERVER_PATH = "${pkgs.vue-language-server}/lib/language-tools/packages/language-server";
    };

    sessionPath = [
      "${home}/.local/bin"
      "$GOPATH/bin"
      "${home}/.cabal/bin" # GHCup and the tools it installs
      "${home}/.ghcup/bin"
    ]
    ++ (
      if isDarwin then
        [
          "${appSupport}/Coursier/bin"
          "${home}/.docker/bin"
        ]
      else
        [ "${home}/.local/share/coursier/bin" ]
    );

    shellAliases = {
      nv = "nvim";
      kc = "kubectl";
      hms = "nix run ${repo}"; # apply this configuration
    };

    file.".ideavimrc".text = ''
      filetype plugin on
      imap jk <Esc>
      set ideajoin
      set surround
      runtime macros/matchit.vim
    '';
  };

  xdg = {
    enable = true;
    configFile = {
      "nix/nix.conf".text = "experimental-features = nix-command flakes\n";
      # A live link, not a store copy: lazy.nvim writes lazy-lock.json back into the repo.
      nvim.source = config.lib.file.mkOutOfStoreSymlink "${repo}/nvim";
    };
  };

  programs = {
    home-manager.enable = true;

    zsh = {
      enable = true;
      syntaxHighlighting.enable = true;
      history.path = "${home}/.zsh_history";
      oh-my-zsh = {
        enable = true;
        plugins = [
          "git"
          "docker"
          "docker-compose"
          "colored-man-pages"
          "history"
          "z"
          "sbt"
          "mix"
          "terraform"
          "aws"
        ]
        ++ lib.optional isDarwin "macos";
      };
      profileExtra = kiro "zprofile.pre.zsh" + kiro "zprofile.post.zsh";
      initContent = lib.mkMerge [
        (lib.mkBefore (kiro "zshrc.pre.zsh"))
        "[[ -s ~/.sdkman/bin/sdkman-init.sh ]] && source ~/.sdkman/bin/sdkman-init.sh"
        (lib.mkAfter (kiro "zshrc.post.zsh"))
      ];
    };

    starship = {
      enable = true;
      settings = lib.importTOML ./starship.toml;
    };

    direnv = {
      enable = true;
      nix-direnv.enable = true;
    };

    fzf.enable = true;

    mise = {
      enable = true;
      globalConfig = {
        tools = {
          elixir = "latest";
          elixir-ls = "latest"; # runs on the Elixir above, unlike the one in nixpkgs
          erlang = "latest";
          go = "latest";
          node = "latest";
          npm = "latest";
          pnpm = "latest";
          python = "latest";
          rust = {
            version = "latest";
            components = "rust-analyzer";
          };
        }
        // lib.genAttrs (map (p: "npm:${p}") [
          "corepack"
          "typescript"
          "node-gyp"
          "vercel"
          "cdk"
          "cline"
          "skills-installer"
          "@virtuslab/tulip"
        ]) (_: "latest");
        settings.npm.package_manager = "pnpm";
      };
    };

    gh = {
      enable = true;
      settings = {
        git_protocol = "https";
        aliases.co = "pr checkout";
      };
    };

    git = {
      enable = true;
      lfs.enable = true;
      signing = {
        key = "A837220BF0502051";
        signByDefault = true;
        format = "openpgp";
        signer = "gpg"; # whichever gpg is on PATH
      };
      ignores = [
        ".DS_Store"
        "**/.claude/settings.local.json"
      ];
      settings = {
        user = {
          name = "yuri4n";
          email = "admin@yurian.land";
        };
        core = {
          autocrlf = "input";
          editor = "nvim";
        };
      };
    };
  };
}
