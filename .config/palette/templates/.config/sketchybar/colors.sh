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

export BAR_COLOR={{bg:0x}}
export BAR_BORDER_COLOR={{surface:0x}}
export BACKGROUND={{surface:0x}}
export FOREGROUND={{fg:0x}}
export ACCENT={{magenta:0x}}
export GREEN={{green:0x}}
export RED={{vermilion:0x}}
export YELLOW={{yellow:0x}}
export BLUE={{blue:0x}}
export PEACH={{terracotta:0x}}
export TEAL={{cyan:0x}}
export LAVENDER={{blue:0x}}
export SUBTEXT={{comment:0x}}
export OVERLAY={{comment:0x}}

# Matisse fills, for chrome that sits behind text rather than being text.
export ULTRAMARINE={{ultramarine:0x}}
export VIRIDIAN={{viridian:0x}}

export TRANSPARENT=0x00000000
