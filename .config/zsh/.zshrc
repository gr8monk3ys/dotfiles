# Homebrew must be on PATH before prompt selection: cold-start shells
# (e.g. a terminal launched from the Dock) get the bare launchd PATH,
# and the starship binary lives in the Homebrew prefix.
# Apple Silicon, Intel, Linuxbrew — first prefix found wins.
for _brew in /opt/homebrew/bin/brew /usr/local/bin/brew /home/linuxbrew/.linuxbrew/bin/brew; do
  if [[ -x "$_brew" ]]; then
    eval "$("$_brew" shellenv)"
    break
  fi
done
unset _brew

# .zshenv already put ~/.local/bin and ~/.cargo/bin first, but on macOS
# /etc/zprofile runs path_helper, which rebuilds PATH with the system dirs
# in front for login shells; brew shellenv above also prepends its prefix.
# Re-prepend once here so user-local binaries beat package-manager shims.
# `typeset -U path` (set in .zshenv) drops the earlier duplicates.
for _dir in "$HOME/.cargo/bin" "$HOME/.local/bin"; do
  [[ -d "$_dir" ]] && path=("$_dir" $path)
done
unset _dir

# Set the directory we want to store zinit and plugins
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"

# Download Zinit, if it's not there yet
if [ ! -d "$ZINIT_HOME" ]; then
   mkdir -p "$(dirname "$ZINIT_HOME")"
   git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
fi

# Source/Load zinit
source "${ZINIT_HOME}/zinit.zsh"

# Completion definitions only; the widgets that must come after compinit
# (fzf-tab, autosuggestions, syntax-highlighting) are loaded below.
zinit light zsh-users/zsh-completions

# Add in snippets
zinit snippet OMZL::git.zsh
zinit snippet OMZP::git
zinit snippet OMZP::sudo
zinit snippet OMZP::command-not-found
# Tool-specific snippets only when the tool exists (archlinux alone adds 21
# sudo-pacman aliases; aws costs ~20ms probing for a binary that isn't there).
[[ "$OSTYPE" == linux* ]] && command -v pacman &> /dev/null && zinit snippet OMZP::archlinux
command -v aws     &> /dev/null && zinit snippet OMZP::aws
command -v kubectl &> /dev/null && zinit snippet OMZP::kubectl
command -v kubectx &> /dev/null && zinit snippet OMZP::kubectx

# Load completions. Only re-scan fpath once a day; otherwise trust the dump
# (-C). A full scan costs ~300ms and a single dangling completion symlink
# makes it happen on every start.
autoload -Uz compinit
_zcompdump="${ZDOTDIR:-$HOME}/.zcompdump"
_zcompdump_stale=( ${_zcompdump}(N.mh+24) )   # N: empty if absent; mh+24: older than a day
if [[ ! -f "$_zcompdump" || ${#_zcompdump_stale} -gt 0 ]]; then
  compinit -d "$_zcompdump"
  touch "$_zcompdump"   # compinit leaves a still-valid dump untouched; reset the day timer
else
  compinit -C -d "$_zcompdump"
fi
unset _zcompdump _zcompdump_stale

zinit cdreplay -q

# Order matters (per fzf-tab's README): fzf-tab after compinit and before
# the widget-wrapping plugins; syntax-highlighting must be last.
zinit light Aloxaf/fzf-tab
zinit light zsh-users/zsh-autosuggestions
zinit light zsh-users/zsh-syntax-highlighting

# OneDark palette for zsh-syntax-highlighting (same hexes as the README
# theme table): valid commands green, errors red, paths underlined, etc.
typeset -A ZSH_HIGHLIGHT_STYLES
ZSH_HIGHLIGHT_STYLES[command]='fg=#98c379'
ZSH_HIGHLIGHT_STYLES[builtin]='fg=#98c379'
ZSH_HIGHLIGHT_STYLES[function]='fg=#98c379'
ZSH_HIGHLIGHT_STYLES[alias]='fg=#98c379'
ZSH_HIGHLIGHT_STYLES[precommand]='fg=#98c379,italic'
ZSH_HIGHLIGHT_STYLES[reserved-word]='fg=#c678dd'
ZSH_HIGHLIGHT_STYLES[unknown-token]='fg=#e06c75'
ZSH_HIGHLIGHT_STYLES[path]='fg=#61afef,underline'
ZSH_HIGHLIGHT_STYLES[globbing]='fg=#56b6c2'
ZSH_HIGHLIGHT_STYLES[single-quoted-argument]='fg=#e5c07b'
ZSH_HIGHLIGHT_STYLES[double-quoted-argument]='fg=#e5c07b'
ZSH_HIGHLIGHT_STYLES[dollar-double-quoted-argument]='fg=#d19a66'
ZSH_HIGHLIGHT_STYLES[comment]='fg=#5c6370,italic'
ZSH_HIGHLIGHT_STYLES[redirection]='fg=#c678dd'

# Prompt: starship (install/Brewfile). Until it is installed, a plain
# two-line prompt so the shell is still usable.
if command -v starship &> /dev/null; then
  export STARSHIP_CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}/starship/starship.toml"
  eval "$(starship init zsh)"
else
  PROMPT='%F{blue}%~%f'$'\n''%F{green}❯%f '
fi

# Keybindings
bindkey -e
bindkey '^p' history-search-backward
bindkey '^n' history-search-forward
bindkey '^[w' kill-region

# History (atuin is the primary store; this is the plain-zsh fallback)
HISTSIZE=50000
SAVEHIST=$HISTSIZE
HISTFILE="${XDG_STATE_HOME:-$HOME/.local/state}/zsh/history"
mkdir -p "${HISTFILE:h}"
setopt sharehistory        # implies incremental append across sessions
setopt hist_ignore_space
setopt hist_ignore_all_dups
setopt hist_save_no_dups
setopt hist_find_no_dups

# Completion styling
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' menu no
# Use eza for fzf-tab previews if available, otherwise fall back to ls
if command -v eza &> /dev/null; then
    zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza --icons --color=always $realpath'
    zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview 'eza --icons --color=always $realpath'
else
    zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls --color $realpath'
    zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview 'ls --color $realpath'
fi

# Core Aliases
alias vim='nvim'
alias c='clear'

# Source aliases file (modern CLI replacements)
[[ -f "${ZDOTDIR:-$HOME/.config/zsh}/aliases.zsh" ]] && source "${ZDOTDIR:-$HOME/.config/zsh}/aliases.zsh"

# Source functions file (fuzzy-finder productivity functions)
[[ -f "${ZDOTDIR:-$HOME/.config/zsh}/functions.zsh" ]] && source "${ZDOTDIR:-$HOME/.config/zsh}/functions.zsh"

# Keep Claude bound to the local installer binary.
if [[ -x "$HOME/.local/bin/claude" ]]; then
    alias claude="$HOME/.local/bin/claude"
    alias claude-code="$HOME/.local/bin/claude"
fi

# ============================================================================
# Shell integrations
# ============================================================================

# fzf - Fuzzy finder
# OneDark palette (matches the README theme table); bg:-1 keeps the
# terminal's own background so Ghostty's frosted glass shows through.
# Inherited by fzf-tab, ctrl-r/ctrl-t, and fzf-based scripts (dotfiles-why).
export FZF_DEFAULT_OPTS="
  --height=60% --layout=reverse --border=rounded --info=inline
  --color=bg:-1,fg:#abb2bf,hl:#61afef
  --color=bg+:#3e4451,fg+:#e6efff,hl+:#61afef
  --color=prompt:#98c379,pointer:#c678dd,marker:#98c379
  --color=info:#e5c07b,spinner:#56b6c2,header:#56b6c2,border:#5c6370"
if command -v fzf &> /dev/null; then
    eval "$(fzf --zsh)"
fi

# zoxide - Smart cd replacement
if command -v zoxide &> /dev/null; then
    eval "$(zoxide init --cmd cd zsh)"
fi

# Atuin - Magical shell history (replaces ctrl-r)
if command -v atuin &> /dev/null; then
    eval "$(atuin init zsh)"
fi

# direnv - Per-directory environment variables
if command -v direnv &> /dev/null; then
    eval "$(direnv hook zsh)"
fi

# mise - Universal version manager (replaces asdf/pyenv/nvm)
if command -v mise &> /dev/null; then
    eval "$(mise activate zsh)"
fi

# Machine type detection (personal, work, server). $(<file) is read by
# zsh itself — no fork, unlike $(cat ...).
if [[ -z "$MACHINE_TYPE" ]]; then
  MACHINE_TYPE="$(<~/.machine_type)" 2>/dev/null
  MACHINE_TYPE="${MACHINE_TYPE:-personal}"
fi
export MACHINE_TYPE

# Load local overrides (not tracked in git)
# Create ~/.config/zsh/zshrc.local for machine-specific settings, and
# zshrc.<machine-type> for per-role settings. Written as `if` rather than
# `[[ ]] &&` so an absent file doesn't leave the shell's exit status at 1.
for _local in zshrc.local "zshrc.${MACHINE_TYPE}"; do
  if [[ -f "${ZDOTDIR:-$HOME/.config/zsh}/${_local}" ]]; then
    source "${ZDOTDIR:-$HOME/.config/zsh}/${_local}"
  fi
done
unset _local
