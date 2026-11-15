#!/usr/bin/env zsh

# ============================================================================
# Rice selection for the shell
# ============================================================================
# The Rice module (palette/rice.sh) owns the choice; here it only picks the
# starship config and points fastfetch and cava at their danse files when
# danse is the rice. Sourced from .zshrc after the prompt is set up; starship
# re-reads STARSHIP_CONFIG on every prompt, so the order is fine.
# rice_select uses builtins only: no fork on the startup path.

DOTFILES_RICE=monochrome-43
if [[ -r "${XDG_CONFIG_HOME:-$HOME/.config}/palette/rice.sh" ]]; then
  source "${XDG_CONFIG_HOME:-$HOME/.config}/palette/rice.sh"
  rice_select
  DOTFILES_RICE="$RICE"
  unset RICE
fi

if [[ "$DOTFILES_RICE" == danse ]]; then
  export STARSHIP_CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}/starship/danse.toml"
  alias fastfetch="fastfetch -c ${XDG_CONFIG_HOME:-$HOME/.config}/fastfetch/danse.jsonc"
  alias cava="cava -p ${XDG_CONFIG_HOME:-$HOME/.config}/cava/danse"
fi
