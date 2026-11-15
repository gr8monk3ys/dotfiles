#!/usr/bin/env zsh

# ============================================================================
# Rice selection for the shell
# ============================================================================
# The Rice module (palette/rice.sh) owns the choice, and every themed tool
# follows it (ADR 0003). Here the shell points each tool at its rice's file,
# all of them rendered by bin/rice-themes:
#
#   prompt          STARSHIP_CONFIG     starship/<rice>.toml (monochrome-43:
#                                       starship.toml, its own powerline)
#   zsh, fzf, eza   sourced             zsh/rices/<rice>.zsh
#   bat             BAT_THEME           bat/themes/<rice>.tmTheme
#   delta           DELTA_FEATURES      git/delta/<rice>.gitconfig
#   eza theme.yml   EZA_CONFIG_DIR      eza/rices/<rice>/
#   yazi            YAZI_CONFIG_HOME    yazi/rices/<rice>/
#   atuin           ATUIN_THEME__NAME   atuin/themes/<rice>.toml
#   zellij          `zellij` function   zellij/themes/<rice>.kdl
#   zathura         `zathura` function  zathura/rices/<rice>/
#
# Neovim reads the rice itself (nvim/lua/palette.lua), so it also follows a
# rice change made after this shell started.
#
# Sourced from .zshrc after the prompt is set up; starship re-reads
# STARSHIP_CONFIG on every prompt, so the order is fine. rice_select uses
# builtins only: no fork on the startup path.

_rice_cfg="${XDG_CONFIG_HOME:-$HOME/.config}"
DOTFILES_RICE=monochrome-43
if [[ -r "$_rice_cfg/palette/rice.sh" ]]; then
  source "$_rice_cfg/palette/rice.sh"
  rice_select
  DOTFILES_RICE="$RICE"
  unset RICE
fi
export DOTFILES_RICE

# Monochrome 43's prompt is the default, starship.toml (set in .zshrc);
# starship/monochrome-43.toml is an opt-in lean alternative, not the rice's.
if [[ "$DOTFILES_RICE" != monochrome-43 && -r "$_rice_cfg/starship/$DOTFILES_RICE.toml" ]]; then
  export STARSHIP_CONFIG="$_rice_cfg/starship/$DOTFILES_RICE.toml"
fi
[[ -r "$_rice_cfg/zsh/rices/$DOTFILES_RICE.zsh" ]] && source "$_rice_cfg/zsh/rices/$DOTFILES_RICE.zsh"

export BAT_THEME="$DOTFILES_RICE"
export DELTA_FEATURES="rice-$DOTFILES_RICE"
export EZA_CONFIG_DIR="$_rice_cfg/eza/rices/$DOTFILES_RICE"
export YAZI_CONFIG_HOME="$_rice_cfg/yazi/rices/$DOTFILES_RICE"
# Atuin layers ATUIN_-prefixed variables over config.toml (`__` nests).
export ATUIN_THEME__NAME="$DOTFILES_RICE"

# Neither reads its theme from the environment. Only a bare `zellij` (a new
# session) takes the rice's theme; subcommands pass straight through.
zellij() {
  if (( $# == 0 )); then
    command zellij options --theme "$DOTFILES_RICE"
  else
    command zellij "$@"
  fi
}
zathura() { command zathura -c "$_rice_cfg/zathura/rices/$DOTFILES_RICE" "$@"; }

# fastfetch and cava have danse variants beside their Monochrome 43 defaults.
# On Omarchy cava's config is rendered from the Omarchy theme instead.
if [[ "$DOTFILES_RICE" == danse ]]; then
  alias fastfetch="fastfetch -c $_rice_cfg/fastfetch/danse.jsonc"
  alias cava="cava -p $_rice_cfg/cava/danse"
fi
