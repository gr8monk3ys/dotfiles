#!/bin/bash

# SketchyBar's view of the shared palette.
#
# The hexes are NOT written here. They come from .config/palette/<rice>.conf,
# the one place this checkout defines a colour, so the bar cannot drift from
# the prompt, Ghostty, Neovim and the desktop background. This file only maps
# palette names onto the role names the item scripts already use.
#
# Read inline rather than through bin/palette: sketchybar execs its scripts
# with a minimal environment and this checkout's bin/ is not reliably on that
# PATH. The file is two fields and a comment character; a parser is overkill.

# Which look: Monochrome 43 (the default) or the older danse rice. The
# choice lives in palette/rice.local - one word, gitignored, per machine:
#   echo danse > ~/.config/palette/rice.local
# Anything else, or no file, is Monochrome 43. borders/bordersrc and
# .zshrc (the prompt) read the same file.
_PALETTE_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/palette"
RICE=monochrome-43
if [ -r "$_PALETTE_DIR/rice.local" ]; then
    read -r RICE < "$_PALETTE_DIR/rice.local" || true
fi
case "$RICE" in
    danse) ;;
    *) RICE=monochrome-43 ;;
esac
export RICE
PALETTE_FILE="$_PALETTE_DIR/$RICE.conf"

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

if [ "$RICE" = monochrome-43 ]; then
    # White on black, greys for structure; colour only for warning/error.
    export BAR_COLOR="$PAL_BG"
    export BAR_BORDER_COLOR="$PAL_INACTIVE"
    export BACKGROUND="$PAL_SURFACE"
    export FOREGROUND="$PAL_FG"
    export ACCENT="$PAL_FG"
    export GREEN="$PAL_FG_DIM"
    export RED="$PAL_DANGER"
    export YELLOW="$PAL_URGENT"
    export BLUE="$PAL_FG"
    export PEACH="$PAL_FG_MUTED"
    export TEAL="$PAL_FG_DIM"
    export LAVENDER="$PAL_FG"
    export SUBTEXT="$PAL_FG_DARK"
    export OVERLAY="$PAL_FG_FAINT"
    export ULTRAMARINE="$PAL_SURFACE"
    export VIRIDIAN="$PAL_SURFACE"
else
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
fi

export TRANSPARENT=0x00000000
