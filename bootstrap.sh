#!/usr/bin/env bash
# Bootstrap dotfiles on a macOS machine.
#   - installs GNU Stow (+ a few CLI tools) via Homebrew
#   - installs the zsh prompt/plugins into ~/.local/share/zsh
#   - backs up any conflicting files, then `stow`s the packages
#
# Safe to re-run. Usage:  ./bootstrap.sh [package ...]   (default: zsh nvim)

set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if (($#)); then PACKAGES=("$@"); else PACKAGES=(zsh nvim); fi
BACKUP_DIR="$HOME/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)"
ZDATA="${XDG_DATA_HOME:-$HOME/.local/share}/zsh"

info() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m!! \033[0m %s\n' "$*"; }

# --- Homebrew -------------------------------------------------------------
if ! command -v brew >/dev/null 2>&1; then
  warn "Homebrew not found. Install it from https://brew.sh and re-run."
  exit 1
fi

# --- CLI dependencies ---------------------------------------------------
info "Installing CLI dependencies via Homebrew"
brew_pkgs=(stow zsh fzf zoxide neovim ripgrep)
missing=()
for p in "${brew_pkgs[@]}"; do
  brew list --formula "$p" >/dev/null 2>&1 || missing+=("$p")
done
if ((${#missing[@]})); then
  brew install "${missing[@]}"
else
  info "All present: ${brew_pkgs[*]}"
fi

# --- zsh prompt + plugins --------------------------------------------
info "Installing zsh prompt and plugins into $ZDATA"
mkdir -p "$ZDATA"
clone_or_pull() {
  local url="$1" dest="$2"
  if [[ -d "$dest/.git" ]]; then
    git -C "$dest" pull --ff-only --quiet && info "updated $(basename "$dest")"
  else
    git clone --depth=1 --quiet "$url" "$dest" && info "cloned $(basename "$dest")"
  fi
}
clone_or_pull https://github.com/romkatv/powerlevel10k.git   "$ZDATA/powerlevel10k"
clone_or_pull https://github.com/zsh-users/zsh-completions.git "$ZDATA/zsh-completions"

# --- stow packages ----------------------------------------------------
# Move any existing real file/dir that would collide into the backup dir.
stow_pkg() {
  local pkg="$1"
  [[ -d "$DOTFILES_DIR/$pkg" ]] || { warn "no package '$pkg', skipping"; return; }

  while IFS= read -r -d '' src; do
    local rel="${src#"$DOTFILES_DIR/$pkg/"}"
    local target="$HOME/$rel"
    if [[ -e "$target" && ! -L "$target" ]]; then
      mkdir -p "$BACKUP_DIR/$(dirname "$rel")"
      mv "$target" "$BACKUP_DIR/$rel"
      warn "backed up ~/$rel -> ${BACKUP_DIR/#$HOME/~}/$rel"
    fi
  done < <(find "$DOTFILES_DIR/$pkg" -type f -print0)

  stow --dir="$DOTFILES_DIR" --target="$HOME" --restow "$pkg"
  info "stowed $pkg"
}

for pkg in "${PACKAGES[@]}"; do
  stow_pkg "$pkg"
done

info "Done. Open a new terminal (or run: exec zsh)."
[[ -d "$BACKUP_DIR" ]] && info "Replaced files are in ${BACKUP_DIR/#$HOME/~}"
cat <<'EOF'

Next steps:
  - Put machine-specific / private shell bits in ~/.zshrc.local (not tracked).
  - Restyle the prompt any time with:  p10k configure
  - Neovim plugins install on first launch (:h vim.pack). Run :checkhealth.
EOF
