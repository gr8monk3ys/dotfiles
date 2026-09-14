#!/bin/bash

# Focused application (left side, after the workspaces).
#
# Ghostty runs with macos-titlebar-style=hidden and AeroSpace moves focus from
# the keyboard, so the window itself often says nothing about what is focused.
# This is the bar's answer to that.

sketchybar --add item front_app left \
    --set front_app \
        icon="$ICON_APP" \
        icon.color="$BLUE" \
        label.color="$FOREGROUND" \
        background.drawing=on \
        script="$PLUGIN_DIR/front_app.sh" \
    --subscribe front_app front_app_switched
