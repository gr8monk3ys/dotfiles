#!/bin/bash

# Total CPU load (right side).

sketchybar --add item cpu right \
    --set cpu \
        icon="$ICON_CPU" \
        icon.color="$GREEN" \
        update_freq=5 \
        script="$PLUGIN_DIR/cpu.sh"
