# dotfiles

Personal macOS config, managed with [GNU Stow](https://www.gnu.org/software/stow/).

```
zsh/     -> ~/.zshenv ~/.zprofile ~/.zshrc ~/.p10k.zsh
nvim/    -> ~/.config/nvim/
```

Each top-level directory is a **stow package**: its contents mirror `$HOME`, so
`stow zsh` symlinks `zsh/.zshrc` to `~/.zshrc`, and so on.

## Install

```sh
git clone git@github.com:toniker/dotfiles.git ~/dotfiles
cd ~/dotfiles
./bootstrap.sh
exec zsh
```

`bootstrap.sh` is idempotent. It:

- installs `stow zsh fzf zoxide neovim ripgrep` via Homebrew (skips what's present),
- installs the prompt + completions into `~/.local/share/zsh/`
  ([powerlevel10k](https://github.com/romkatv/powerlevel10k),
  [zsh-completions](https://github.com/zsh-users/zsh-completions)),
- moves any existing real files that would collide into `~/.dotfiles-backup/<timestamp>/`,
- `stow`s the `zsh` and `nvim` packages.

Manual equivalent for a single package: `stow --restow zsh`.
To remove: `stow -D zsh`.

## The zsh setup

Framework-free, tuned for fast startup (~0.2 s warm, instant-prompt makes it feel
immediate). Highlights:

- **powerlevel10k** prompt with instant prompt; config in `zsh/.p10k.zsh`
  (regenerate with `p10k configure`).
- `zoxide` (`z`) and `fzf` key bindings (`Ctrl-R`, `Ctrl-T`, `Alt-C`), their init
  **cached** under `~/.cache/zsh/` and refreshed only when the binary changes.
- `compinit` runs its security check once a day, otherwise loads the cached dump.
- Homebrew env is set statically in `.zprofile` (no `brew shellenv` subprocess).
- Newest installed nvm Node is added to `PATH` without sourcing `nvm.sh`; `nvm`
  itself lazy-loads on first call.
- Curated git aliases (`gst`, `gco`, `gcb`, `gwt`, ...) — see `zsh/.zshrc` §7.

### Machine-specific / private settings

`~/.zshrc.local` is sourced at the end of `.zshrc` and is **not** tracked here.
Put per-machine `PATH` entries, work-only functions, and secrets there:

```sh
# ~/.zshrc.local
path+=("$HOME/some/machine/specific/bin")
export SOME_TOKEN=...
```

## The nvim setup

Minimal Neovim config (single `init.lua`), originally derived from
[kickstart.nvim](https://github.com/nvim-lua/kickstart.nvim). Uses the built-in
`vim.pack` plugin manager; plugin revisions are pinned in `nvim-pack-lock.json`.
Plugins install on first launch. See `nvim/.config/nvim/README.md`.
