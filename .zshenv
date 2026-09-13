# default apps
export EDITOR="nvim"
export VISUAL="nvim"
export TERMINAL="ghostty"
export BROWSER="firefox"

# default folders
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_STATE_HOME="$HOME/.local/state"
export XDG_CACHE_HOME="$HOME/.cache"
export XDG_SCREENSHOTS_DIR="$HOME/Pictures/screenshots"

# Keep PATH free of duplicates (path and PATH are tied in zsh).
typeset -U path

# add ~/.local/bin and its first-level subfolders to PATH (portable on
# macOS/Linux). .zshrc re-prepends the user dirs once more because
# path_helper/brew shellenv reorder PATH after this file runs.
if [[ -d "$HOME/.local/bin" ]]; then
  export PATH="$HOME/.local/bin:$PATH"
  for dir in "$HOME/.local/bin"/*(/N); do
    export PATH="$PATH:$dir"
  done
fi

# Cargo installs binaries like `rustlings` here.
if [[ -d "$HOME/.cargo/bin" ]]; then
  export PATH="$HOME/.cargo/bin:$PATH"
fi

# cleaning up the home folder
export LESSHISTFILE="-"
export ZDOTDIR="$XDG_CONFIG_HOME/zsh"

# npm has no XDG support: point it at the tracked config, which moves the
# global prefix out of the Homebrew Cellar (see .config/npm/README.md).
export NPM_CONFIG_USERCONFIG="$XDG_CONFIG_HOME/npm/npmrc"

# curl and wget predate XDG and look in $HOME. Without these, the tracked
# .curlrc and .wgetrc are linked into ~/.config/ and read by nothing — the
# same defect that left git's config and Firefox's user.js inert.
export CURL_HOME="$XDG_CONFIG_HOME/curl"
export WGETRC="$XDG_CONFIG_HOME/wget/.wgetrc"
export SCREENRC="$XDG_CONFIG_HOME/macos/.screenrc"
# eza reads ONLY $EZA_CONFIG_DIR; it does not fall back to $XDG_CONFIG_HOME.
export EZA_CONFIG_DIR="$XDG_CONFIG_HOME/eza"

# colors!
export BAT_THEME="base16-onedark"
export MANPAGER="nvim +Man!"

# set the localization. LANG (not LC_ALL) so finer LC_* settings still
# apply and boxes without this locale don't warn on every command.
export LANG=en_US.UTF-8
