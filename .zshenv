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
# eza defaults EZA_CONFIG_DIR to $XDG_CONFIG_HOME/eza already; set explicitly
# so it survives an unset XDG_CONFIG_HOME.
export EZA_CONFIG_DIR="$XDG_CONFIG_HOME/eza"

# theme.yml needs a build feature Homebrew's bottle does not enable — this
# eza reports "v0.23.5 [+git]" and nothing else, and silently ignores the
# file, malformed YAML included. EZA_COLORS is what this build honours, so
# the OneDark palette from .config/eza/theme.yml is expressed here too.
# Keys: di=dir ln=symlink ex=executable pi=pipe so=socket bd/cd=devices
#       fi=file u*=permission bits g*=git status da=date uu/gu=user/group
export EZA_COLORS="di=38;2;97;175;239:ln=38;2;86;182;194:ex=38;2;152;195;121:pi=38;2;229;192;123:so=38;2;198;120;221:bd=38;2;229;192;123:cd=38;2;229;192;123:fi=38;2;171;178;191:ur=38;2;229;192;123:uw=38;2;224;106;81:ux=38;2;152;195;121:gm=38;2;152;195;121:ga=38;2;229;192;123:gd=38;2;224;106;81:da=38;2;92;99;112:uu=38;2;171;178;191:gu=38;2;92;99;112"

# colors!
export BAT_THEME="danse"
export MANPAGER="nvim +Man!"

# set the localization. LANG (not LC_ALL) so finer LC_* settings still
# apply and boxes without this locale don't warn on every command.
export LANG=en_US.UTF-8
