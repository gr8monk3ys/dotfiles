#!/bin/bash

# AeroSpace workspace change handler
# Highlights the active workspace indicator

source "$CONFIG_DIR/colors.sh"

if [ "$1" = "$FOCUSED_WORKSPACE" ]; then
    sketchybar --set "$NAME" background.drawing=on \
        background.color=$ACCENT \
        icon.color=$BAR_COLOR
else
    sketchybar --set "$NAME" background.drawing=off \
        icon.color=$FOREGROUND
fi
