#!/usr/bin/env zsh

# ============================================================================
# Rice selection for the shell
# ============================================================================
# Monochrome 43 is the default look; `danse` in ~/.config/palette/rice.local
# (one word, gitignored) opts back in to the older one. SketchyBar and borders
# read the same file. Here it picks the starship config and points fastfetch
# and cava at their danse files. Sourced from .zshrc after the prompt is set
# up; starship re-reads STARSHIP_CONFIG on every prompt, so the order is fine.
# `read` is a builtin: no fork on the startup path.

_rice_file="${XDG_CONFIG_HOME:-$HOME/.config}/palette/rice.local"
DOTFILES_RICE=monochrome-43
if [[ -r "$_rice_file" ]]; then
  read -r DOTFILES_RICE < "$_rice_file" || true
fi
[[ "$DOTFILES_RICE" == danse ]] || DOTFILES_RICE=monochrome-43
unset _rice_file

if [[ "$DOTFILES_RICE" == danse ]]; then
  export STARSHIP_CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}/starship/danse.toml"
  alias fastfetch="fastfetch -c ${XDG_CONFIG_HOME:-$HOME/.config}/fastfetch/danse.jsonc"
  alias cava="cava -p ${XDG_CONFIG_HOME:-$HOME/.config}/cava/danse"
fi
