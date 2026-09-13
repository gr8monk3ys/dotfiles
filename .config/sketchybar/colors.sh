#!/bin/bash

# SketchyBar's view of the shared palette.
#
# The hexes are NOT written here. They come from .config/palette/danse.conf,
# the one place this checkout defines a colour, so the bar cannot drift from
# the prompt, Ghostty, Neovim and the desktop background. This file only maps
# palette names onto the role names the item scripts already use.
#
# Read inline rather than through bin/palette: sketchybar execs its scripts
# with a minimal environment and this checkout's bin/ is not reliably on that
# PATH. The file is two fields and a comment character; a parser is overkill.

PALETTE_FILE="${XDG_CONFIG_HOME:-$HOME/.config}/palette/danse.conf"

# name -> 0xaarrggbb, as $PAL_<NAME> with kebab-case folded to underscores.
if [ -r "$PALETTE_FILE" ]; then
    while IFS='|' read -r _name _hex _role; do
        case "$_name" in '' | \#*) continue ;; esac
        _var="PAL_$(printf '%s' "$_name" | tr '[:lower:]-' '[:upper:]_')"
        eval "$_var=0xff${_hex#\#}"
    done < "$PALETTE_FILE"
    unset _name _hex _role _var
else
    echo "sketchybar/colors.sh: cannot read $PALETTE_FILE" >&2
fi

export BAR_COLOR="$PAL_BG"
export BAR_BORDER_COLOR="$PAL_SURFACE"
export BACKGROUND="$PAL_SURFACE"
export FOREGROUND="$PAL_FG"
export ACCENT="$PAL_MAGENTA"
export GREEN="$PAL_GREEN"
export RED="$PAL_VERMILION"
export YELLOW="$PAL_YELLOW"
export BLUE="$PAL_BLUE"
export PEACH="$PAL_TERRACOTTA"
export TEAL="$PAL_CYAN"
export LAVENDER="$PAL_BLUE"
export SUBTEXT="$PAL_COMMENT"
export OVERLAY="$PAL_COMMENT"

# Matisse fills, for chrome that sits behind text rather than being text.
export ULTRAMARINE="$PAL_ULTRAMARINE"
export VIRIDIAN="$PAL_VIRIDIAN"

export TRANSPARENT=0x00000000
