#!/bin/bash

# Date and time display (right side)

sketchybar --add item calendar right \
    --set calendar \
        icon="$ICON_CALENDAR" \
        icon.color="$TEAL" \
        update_freq=30 \
        script="sketchybar --set \$NAME label=\"\$(date '+%a %d %b  %H:%M')\"" \
    --subscribe calendar system_woke
