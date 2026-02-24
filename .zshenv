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

# add ~/.local/bin and first-level subfolders to PATH (portable on macOS/Linux)
if [[ -d "$HOME/.local/bin" ]]; then
  export PATH="$PATH:$HOME/.local/bin"
  for dir in "$HOME/.local/bin"/*(/N); do
    export PATH="$PATH:$dir"
  done
fi

# Add common Nix profile paths when Nix is installed
for dir in "/nix/var/nix/profiles/default/bin" "$HOME/.nix-profile/bin"; do
  if [[ -d "$dir" ]] && [[ ":$PATH:" != *":$dir:"* ]]; then
    export PATH="$dir:$PATH"
  fi
done

# cleaning up the home folder
export LESSHISTFILE="-"
export ZDOTDIR="$XDG_CONFIG_HOME/zsh"
export _ZL_DATA="$XDG_CACHE_HOME/zsh/.zlua"

# colors!
export BAT_THEME="base16-onedark"
export MANPAGER="nvim +Man!"

# set the localization
export LC_ALL=en_US.UTF-8
