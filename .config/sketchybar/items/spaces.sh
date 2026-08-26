#!/bin/bash

# AeroSpace workspace indicators
# Each workspace gets a clickable item; the active one is highlighted

SPACE_ICONS=("1" "2" "3" "4" "5" "6" "7" "8" "9")

for i in "${!SPACE_ICONS[@]}"; do
    sid="$((i + 1))"
    sketchybar --add item space.$sid left \
        --subscribe space.$sid aerospace_workspace_change \
        --set space.$sid \
            icon="${SPACE_ICONS[$i]}" \
            icon.padding_left=7 \
            icon.padding_right=7 \
            background.color="$BACKGROUND" \
            background.corner_radius=5 \
            background.height=24 \
            background.drawing=off \
            label.drawing=off \
            script="$PLUGIN_DIR/aerospacer.sh $sid" \
            click_script="aerospace workspace $sid"
done
