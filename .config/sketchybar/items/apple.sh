#!/bin/bash

# Apple menu item — popup with quick actions

sketchybar --add item apple.logo left \
    --set apple.logo \
        icon="$ICON_APPLE" \
        icon.font="SF Pro:Black:16.0" \
        icon.color="$ACCENT" \
        background.drawing=off \
        label.drawing=off \
        click_script="sketchybar -m --set \$NAME popup.drawing=toggle" \
        popup.background.color="$BAR_COLOR" \
        popup.background.border_color="$BAR_BORDER_COLOR" \
        popup.background.border_width=2 \
        popup.background.corner_radius=9 \
    \
    --add item apple.prefs popup.apple.logo \
    --set apple.prefs \
        icon="$ICON_PREFERENCES" \
        label="Preferences" \
        click_script="open -a 'System Settings'; sketchybar -m --set apple.logo popup.drawing=off" \
    \
    --add item apple.activity popup.apple.logo \
    --set apple.activity \
        icon="$ICON_ACTIVITY" \
        label="Activity" \
        click_script="open -a 'Activity Monitor'; sketchybar -m --set apple.logo popup.drawing=off" \
    \
    --add item apple.lock popup.apple.logo \
    --set apple.lock \
        icon="$ICON_LOCK" \
        label="Lock Screen" \
        click_script="pmset displaysleepnow; sketchybar -m --set apple.logo popup.drawing=off"
