#!/bin/bash

# SketchyBar's view of the shared palette.
#
# Rendered by bin/palette from .config/palette/templates/.config/sketchybar/colors.sh.
# Edit the template, then run `palette render`; `palette check` fails on hand edits.
#
# The hexes are rendered in rather than read at runtime: sketchybar execs its
# scripts with a minimal environment, so a file with nothing to parse and
# nothing to find on PATH is the one that cannot fail. This file only maps
# palette names onto the role names the item scripts already use.

export BAR_COLOR=0xff282c34
export BAR_BORDER_COLOR=0xff3e4451
export BACKGROUND=0xff3e4451
export FOREGROUND=0xffabb2bf
export ACCENT=0xffc678dd
export GREEN=0xff98c379
export RED=0xffe06a51
export YELLOW=0xffe5c07b
export BLUE=0xff61afef
export PEACH=0xffd98c5c
export TEAL=0xff56b6c2
export LAVENDER=0xff61afef
export SUBTEXT=0xff5c6370
export OVERLAY=0xff5c6370

# Matisse fills, for chrome that sits behind text rather than being text.
export ULTRAMARINE=0xff2b4468
export VIRIDIAN=0xff476a62

export TRANSPARENT=0x00000000
