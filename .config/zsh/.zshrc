# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

if [[ -f "/opt/homebrew/bin/brew" ]]; then
  # If you're using macOS, you'll want this enabled
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# Prefer user-local binaries before package manager shims.
if [[ -d "$HOME/.local/bin" ]]; then
  path=("$HOME/.local/bin" "${(@)path:#$HOME/.local/bin}")
fi

# Cargo installs binaries like `rustlings` here.
if [[ -d "$HOME/.cargo/bin" ]]; then
  path=("$HOME/.cargo/bin" "${(@)path:#$HOME/.cargo/bin}")
fi

# Set the directory we want to store zinit and plugins
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"

# Download Zinit, if it's not there yet
if [ ! -d "$ZINIT_HOME" ]; then
   mkdir -p "$(dirname "$ZINIT_HOME")"
   git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
fi

# Source/Load zinit
source "${ZINIT_HOME}/zinit.zsh"

# Add in Powerlevel10k
zinit ice depth=1; zinit light romkatv/powerlevel10k

# Add in zsh plugins
zinit light zsh-users/zsh-syntax-highlighting
zinit light zsh-users/zsh-completions
zinit light zsh-users/zsh-autosuggestions
zinit light Aloxaf/fzf-tab

# Add in snippets
zinit snippet OMZL::git.zsh
zinit snippet OMZP::git
zinit snippet OMZP::sudo
zinit snippet OMZP::archlinux
zinit snippet OMZP::aws
zinit snippet OMZP::kubectl
zinit snippet OMZP::kubectx
zinit snippet OMZP::command-not-found

# Load completions
autoload -Uz compinit && compinit

zinit cdreplay -q

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

# To customize prompt, run `p10k configure` and edit ~/.p10k.zsh.
# Fallback to repo-managed config when no personal prompt config exists.
if [[ -f "$HOME/.p10k.zsh" ]]; then
  source "$HOME/.p10k.zsh"
elif [[ -f "${ZDOTDIR:-$HOME/.config/zsh}/.p10k.zsh" ]]; then
  source "${ZDOTDIR:-$HOME/.config/zsh}/.p10k.zsh"
fi

# Keybindings
bindkey -e
bindkey '^p' history-search-backward
bindkey '^n' history-search-forward
bindkey '^[w' kill-region

# History
HISTSIZE=5000
HISTFILE="${XDG_STATE_HOME:-$HOME/.local/state}/zsh/history"
mkdir -p "${XDG_STATE_HOME:-$HOME/.local/state}/zsh"
SAVEHIST=$HISTSIZE
setopt appendhistory
setopt sharehistory
setopt hist_ignore_space
setopt hist_ignore_all_dups
setopt hist_save_no_dups
setopt hist_ignore_dups
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

# Machine type detection (personal, work, server)
export MACHINE_TYPE="${MACHINE_TYPE:-$(cat ~/.machine_type 2>/dev/null || echo 'personal')}"

# Load local overrides (not tracked in git)
# Create ~/.config/zsh/zshrc.local for machine-specific settings
[[ -f "${ZDOTDIR:-$HOME/.config/zsh}/zshrc.local" ]] && source "${ZDOTDIR:-$HOME/.config/zsh}/zshrc.local"

# Load machine-type specific config if it exists
[[ -f "${ZDOTDIR:-$HOME/.config/zsh}/zshrc.${MACHINE_TYPE}" ]] && source "${ZDOTDIR:-$HOME/.config/zsh}/zshrc.${MACHINE_TYPE}"
