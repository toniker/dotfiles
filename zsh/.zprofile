# ~/.zprofile — login-shell setup (runs once per login shell, before ~/.zshrc)

# Homebrew environment, static.
# Equivalent to `eval "$(/opt/homebrew/bin/brew shellenv)"` but without spawning
# Ruby on every login shell (~300ms). PATH already gets /opt/homebrew/bin from
# the system /etc/zprofile -> path_helper -> /etc/paths.d/homebrew; we only add
# sbin and the HOMEBREW_* vars here.
export HOMEBREW_PREFIX="/opt/homebrew"
export HOMEBREW_CELLAR="/opt/homebrew/Cellar"
export HOMEBREW_REPOSITORY="/opt/homebrew"
export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:$PATH"
export INFOPATH="/opt/homebrew/share/info${INFOPATH:+:$INFOPATH}"

# fzf key-bindings/completion and zoxide are interactive-only; they are set up
# (cached) in ~/.zshrc. Do not duplicate them here.
