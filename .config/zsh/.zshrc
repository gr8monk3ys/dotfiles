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

# Set the directory we want to store zinit and plugins
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"

# Download Zinit, if it's not there yet
if [ ! -d "$ZINIT_HOME" ]; then
   mkdir -p "$(dirname $ZINIT_HOME)"
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

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# Keybindings
bindkey -e
bindkey '^p' history-search-backward
bindkey '^n' history-search-forward
bindkey '^[w' kill-region

# History
HISTSIZE=5000
HISTFILE=~/.zsh_history
SAVEHIST=$HISTSIZE
HISTDUP=erase
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

# Core Aliases (modern replacements loaded from ~/.config/.aliases)
alias vim='nvim'
alias c='clear'

# Source aliases file
[[ -f "${XDG_CONFIG_HOME:-$HOME/.config}/.aliases" ]] && source "${XDG_CONFIG_HOME:-$HOME/.config}/.aliases"

# ============================================================================
# Shell integrations
# ============================================================================

# fzf - Fuzzy finder
eval "$(fzf --zsh)"

# zoxide - Smart cd replacement
eval "$(zoxide init --cmd cd zsh)"

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