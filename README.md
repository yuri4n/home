# home

My setup as a [Home Manager](https://github.com/nix-community/home-manager) flake:
zsh with oh-my-zsh and starship, signed git commits, mise, Neovim, and Zed with
a profile per language stack. It works on macOS (Intel and Apple silicon) and Linux.

Neovim and Zed's vim mode share one set of keys. The
[cheat sheet](https://github.com/yuri4n/nvim/blob/main/CHEATSHEET.md) lists them.

## Install

You need Nix. Clone the repo with its submodule to the path that the config
expects, apply it, then install the mise tools (languages, ElixirLS,
rust-analyzer):

```sh
git clone --recurse-submodules https://github.com/yuri4n/home ~/.config/home-manager
nix --extra-experimental-features 'nix-command flakes' run ~/.config/home-manager
mise install
```

After the first run, flakes are on and `hms` applies changes. Files that Home
Manager replaces are kept as `*.backup`. If your user name on a machine is not
`yuri4n`, change `user` in `flake.nix`.

For Haskell, install GHCup once. The shell already has its PATH, and this
command does not edit shell files:

```sh
curl --proto '=https' --tlsv1.2 -sSf https://get-ghcup.haskell.org | BOOTSTRAP_HASKELL_NONINTERACTIVE=1 BOOTSTRAP_HASKELL_INSTALL_HLS=1 sh
```

## Files

| File            | Contents                                                           |
| --------------- | ------------------------------------------------------------------ |
| `flake.nix`     | Inputs, one configuration per platform, `nix run`                  |
| `home.nix`      | Shell, prompt, git, mise, CLI tools, language servers, Neovim link |
| `zed.nix`       | Zed settings, keymap, extensions and profiles                      |
| `nvim/`         | [yuri4n/nvim](https://github.com/yuri4n/nvim) as a submodule, linked live |
| `starship.toml` | Prompt                                                             |

## Zed profiles

Switch profiles with `ctrl-alt-cmd-p` (Linux: `ctrl-alt-super-p`), or run
`settings profile selector: toggle`. Every language works in every profile.
A profile only adds what one stack needs. Every profile turns on inlay hints
and code lenses.

| Profile          | Adds                                                     |
| ---------------- | -------------------------------------------------------- |
| Scala            | Metals super-method lenses                               |
| Frontend         | TypeScript and Vue hints, Anysphere and One Light themes |
| Scala + Frontend | Scala and Frontend together                              |
| Elixir           | ElixirLS test lenses                                     |
| Phoenix          | Elixir, TypeScript hints, Tailwind in HEEx               |
| Python           | basedpyright in `standard` type checking                 |
| Rust             | Lifetime and closure hints                               |
| Go               | gopls hints and code lenses                              |
| C/C++            | clangd hints                                             |
| C#               | Roslyn hints                                             |
| Deno             | The Deno language server for JavaScript and TypeScript   |

Zed can still change its own `settings.json`. On each switch, the keys in
`zed.nix` overwrite the same keys there, and everything else stays local
(for example, agent models and permissions).

## Notes

- nixpkgs 26.05 is the last release that supports Intel Macs. On other
  machines you can move to `nixpkgs-unstable` and home-manager `master`.
- On macOS, Nix does not install Zed, because Zed.app updates itself. A switch
  makes Zed the default app for code files. On Linux, Zed comes from nixpkgs
  (`zeditor`, aliased as `zed`).
- Neovim's language servers come from Nix. ElixirLS and rust-analyzer come
  from mise, and HLS from GHCup, because they must match the toolchain.
- To change the Neovim config, commit in `nvim/`, push, then commit the new
  submodule revision here.
- Not in the repo: the AnnotationMono Nerd Font (installed by hand; MartianMono
  is the fallback), and SDKMAN, Kiro CLI and Docker Desktop (their shell hooks
  load only when they are installed).
