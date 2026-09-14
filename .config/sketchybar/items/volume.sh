#!/bin/bash

# Output volume (right side). Event-driven; no polling.

sketchybar --add item volume right \
    --set volume \
        icon.color="$TEAL" \
        script="$PLUGIN_DIR/volume.sh" \
    --subscribe volume volume_change
