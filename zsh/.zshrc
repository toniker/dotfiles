# ~/.zshrc — no framework, Powerlevel10k prompt. Optimized for fast startup.
#
# Profile startup with:  ZSH_PROFILE=1 zsh -i -c exit
# Machine-specific / private settings go in ~/.zshrc.local (not tracked).

# ---------------------------------------------------------------------------
# 1. Powerlevel10k instant prompt — MUST stay at the top, before any output.
#    Anything that prints to the console or reads input has to come after this.
# ---------------------------------------------------------------------------
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

if [[ -n "$ZSH_PROFILE" ]]; then
  zmodload zsh/zprof
fi

# ---------------------------------------------------------------------------
# 2. PATH and environment
# ---------------------------------------------------------------------------
typeset -U path fpath          # keep entries unique

# nvm: put the newest installed Node on PATH without sourcing nvm.sh (~200ms).
# Pin a specific version by setting NODE_VERSION in ~/.zshrc.local.
export NVM_DIR="$HOME/.nvm"
_nvm_nodes=("$NVM_DIR"/versions/node/*(N/:t))   # e.g. (v22.4.0 v24.6.0)
if (( ${#_nvm_nodes} )); then
  : ${NODE_VERSION:=${${(On)_nvm_nodes}[1]}}    # newest, numeric sort
  _nvm_root="$NVM_DIR/versions/node/$NODE_VERSION"
  if [[ -d "$_nvm_root/bin" ]]; then
    path=("$_nvm_root/bin" $path)
    export NVM_BIN="$_nvm_root/bin"
    export NVM_INC="$_nvm_root/include/node"
  fi
  unset _nvm_root
fi
unset _nvm_nodes
# Lazy `nvm`: the real nvm loads only the first time you actually call it.
nvm() { unfunction nvm; [[ -s "$NVM_DIR/nvm.sh" ]] && source "$NVM_DIR/nvm.sh"; nvm "$@"; }

path=(
  "$HOME/.local/bin"
  "$HOME/.antigravity/antigravity/bin"
  $path
  "$HOME/.lmstudio/bin"
)
export PATH

# ---------------------------------------------------------------------------
# 3. History
# ---------------------------------------------------------------------------
HISTFILE="$HOME/.zsh_history"
HISTSIZE=100000
SAVEHIST=100000
setopt EXTENDED_HISTORY          # timestamp each entry
setopt SHARE_HISTORY             # live-share history across running shells
setopt HIST_IGNORE_DUPS          # don't record a line equal to the previous
setopt HIST_IGNORE_ALL_DUPS      # drop older duplicate when a line repeats
setopt HIST_IGNORE_SPACE         # a leading space hides the line from history
setopt HIST_FIND_NO_DUPS         # don't show dupes when scrolling through history
setopt HIST_SAVE_NO_DUPS
setopt HIST_REDUCE_BLANKS
setopt HIST_VERIFY               # expand !! etc. onto the line instead of running

# ---------------------------------------------------------------------------
# 4. Shell options
# ---------------------------------------------------------------------------
setopt AUTO_CD                   # `foo` == `cd foo` when foo is a directory
setopt AUTO_PUSHD PUSHD_IGNORE_DUPS PUSHD_SILENT
setopt EXTENDED_GLOB
setopt INTERACTIVE_COMMENTS      # allow `# comments` in the interactive shell
setopt NO_BEEP
setopt NO_FLOW_CONTROL           # free up Ctrl-S / Ctrl-Q
setopt COMPLETE_IN_WORD ALWAYS_TO_END
setopt NUMERIC_GLOB_SORT

# ---------------------------------------------------------------------------
# 5. Completion — compinit with a once-a-day security check, dump cached & compiled
# ---------------------------------------------------------------------------
_zsh_cache="${XDG_CACHE_HOME:-$HOME/.cache}/zsh"
[[ -d $_zsh_cache ]] || mkdir -p $_zsh_cache

# Homebrew completions (Apple Silicon and Intel prefixes).
fpath=(/opt/homebrew/share/zsh/site-functions /usr/local/share/zsh/site-functions $fpath)
# zsh-completions bundle (installed by bootstrap.sh).
fpath+=("${XDG_DATA_HOME:-$HOME/.local/share}/zsh/zsh-completions/src")

zmodload zsh/complist
autoload -Uz compinit
_zcompdump="$_zsh_cache/zcompdump-$ZSH_VERSION"
if [[ ! -s "$_zcompdump" || -n "$_zcompdump"(#qNmh+24) ]]; then
  compinit -i -d "$_zcompdump"    # missing or >24h old: full run, re-scans fpath
  touch "$_zcompdump"
else
  compinit -C -d "$_zcompdump"    # fresh: trust the dump, skip the slow scan
fi
# Byte-compile the dump in the background so next start is faster.
{
  [[ -s "$_zcompdump" && ( ! -s "$_zcompdump.zwc" || "$_zcompdump" -nt "$_zcompdump.zwc" ) ]] \
    && zcompile "$_zcompdump"
} &!

zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|=*' 'l:|=* r:|=*'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' group-name ''
zstyle ':completion:*:descriptions' format '%F{yellow}-- %d --%f'
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path "$_zsh_cache/zcompcache"
zstyle ':completion:*' special-dirs true

# ---------------------------------------------------------------------------
# 6. Key bindings (emacs-style + sensible terminal keys)
# ---------------------------------------------------------------------------
bindkey -e

autoload -Uz up-line-or-beginning-search down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search
bindkey '^[[A' up-line-or-beginning-search
bindkey '^[OA' up-line-or-beginning-search
bindkey '^[[B' down-line-or-beginning-search
bindkey '^[OB' down-line-or-beginning-search
bindkey '^P'   up-line-or-beginning-search
bindkey '^N'   down-line-or-beginning-search

bindkey '^[[H'  beginning-of-line       # Home
bindkey '^[OH'  beginning-of-line
bindkey '^[[F'  end-of-line             # End
bindkey '^[OF'  end-of-line
bindkey '^[[3~' delete-char             # Delete
bindkey '^[[1;5C' forward-word          # Ctrl-Right
bindkey '^[[1;5D' backward-word         # Ctrl-Left
bindkey '^[[1;3C' forward-word          # Alt-Right
bindkey '^[[1;3D' backward-word         # Alt-Left
bindkey '^[[3;5~' kill-word             # Ctrl-Delete
bindkey '^[^?'  backward-kill-word      # Alt-Backspace
bindkey '^[[Z'  reverse-menu-complete   # Shift-Tab

# ---------------------------------------------------------------------------
# 7. Aliases
# ---------------------------------------------------------------------------
export CLICOLOR=1
alias ls='ls -G'
alias l='ls -lah'
alias ll='ls -lh'
alias la='ls -lAh'
alias md='mkdir -p'
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'

# git — the subset from shell history plus the common Oh My Zsh names
alias g='git'
alias gst='git status'
alias gss='git status -s'
alias ga='git add'
alias gaa='git add --all'
alias gc='git commit -v'
alias gcm='git commit -m'
alias gca='git commit -v --amend'
alias gcan='git commit -v --amend --no-edit'
alias gco='git checkout'
alias gcb='git checkout -b'
alias gsw='git switch'
alias gswc='git switch -c'
alias gb='git branch'
alias gbd='git branch -d'
alias gbD='git branch -D'
alias gd='git diff'
alias gds='git diff --staged'
alias gf='git fetch'
alias gfa='git fetch --all --prune'
alias gl='git pull'
alias gp='git push'
alias gpf='git push --force-with-lease'
alias glog='git log --oneline --graph --decorate'
alias glga='git log --oneline --graph --decorate --all'
alias gls='git log --stat'
alias gm='git merge'
alias grb='git rebase'
alias grbi='git rebase -i'
alias grbc='git rebase --continue'
alias grba='git rebase --abort'
alias grs='git restore'
alias grss='git restore --staged'
alias grh='git reset'
alias grhh='git reset --hard'
alias gsta='git stash'
alias gstp='git stash pop'
alias gstl='git stash list'
alias gwt='git worktree'
alias gwta='git worktree add'
alias gwtl='git worktree list'
alias gwtr='git worktree remove'
alias grt='cd "$(git rev-parse --show-toplevel 2>/dev/null || echo .)"'

# ---------------------------------------------------------------------------
# 8. Tools — cached init (regenerated only when the binary is newer than the cache)
# ---------------------------------------------------------------------------
zcache() {  # zcache <name> <cmd> [args...] — cache stdout of <cmd> and source it
  local f="$_zsh_cache/$1.zsh" bin="$2"
  (( $+commands[$bin] )) || return 0
  if [[ ! -s $f || $commands[$bin] -nt $f ]]; then
    shift
    "$@" > "$f"
  fi
  source "$f"
}
zcache zoxide zoxide init zsh
zcache fzf fzf --zsh

# Powerlevel10k prompt (installed by bootstrap.sh)
_p10k="${XDG_DATA_HOME:-$HOME/.local/share}/zsh/powerlevel10k/powerlevel10k.zsh-theme"
[[ -r "$_p10k" ]] && source "$_p10k"
unset _p10k
[[ -r "$HOME/.p10k.zsh" ]] && source "$HOME/.p10k.zsh"

# ---------------------------------------------------------------------------
# 9. Local overrides — machine-specific and private (not tracked in dotfiles)
# ---------------------------------------------------------------------------
[[ -r "$HOME/.local/bin/env" ]] && . "$HOME/.local/bin/env"
[[ -r "$HOME/.zshrc.local" ]] && . "$HOME/.zshrc.local"

if [[ -n "$ZSH_PROFILE" ]]; then
  zprof
fi
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# Claude Code CLI via Amazon Bedrock (scoped to this command so the desktop app uses the enterprise login)
claude() {
  CLAUDE_CODE_USE_BEDROCK=1 \
  AWS_REGION=eu-north-1 \
  AWS_PROFILE=default \
  ANTHROPIC_DEFAULT_SONNET_MODEL='eu.anthropic.claude-sonnet-5[1m]' \
  ANTHROPIC_DEFAULT_OPUS_MODEL='global.anthropic.claude-opus-5-5[1m]' \
  ANTHROPIC_DEFAULT_HAIKU_MODEL='eu.anthropic.claude-haiku-4-5-20251001-v1:0' \
  ANTHROPIC_DEFAULT_FABLE_MODEL='global.anthropic.claude-fable-5-1[1m]' \
  command claude "$@"
}

alias has_conflicts='(git merge-tree --write-tree --name-only HEAD origin/develop >/dev/null; merge_tree_status=$?; case $merge_tree_status in 0) print no;; 1) print yes;; *) exit $merge_tree_status;; esac)'
