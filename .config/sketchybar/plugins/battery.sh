#!/bin/bash

# On a desktop with no battery, pmset reports no percentage: draw nothing
# rather than an empty item.

source "$CONFIG_DIR/colors.sh"
source "$CONFIG_DIR/icons.sh"

INFO_LINE="$(pmset -g batt)"
PERCENT="$(printf '%s\n' "$INFO_LINE" | grep -Eo '[0-9]+%' | head -1 | tr -d '%')"
if [ -z "$PERCENT" ]; then
    sketchybar --set "$NAME" drawing=off
    exit 0
fi

CHARGING=""
printf '%s\n' "$INFO_LINE" | grep -q 'AC Power' && CHARGING=yes

COLOR="$FOREGROUND"
case "$PERCENT" in
    100 | 9[0-9] | 8[0-9]) ICON="$ICON_BATTERY_100" ;;
    7[0-9] | 6[0-9]) ICON="$ICON_BATTERY_75" ;;
    5[0-9] | 4[0-9]) ICON="$ICON_BATTERY_50" ;;
    3[0-9] | 2[0-9]) ICON="$ICON_BATTERY_25"; COLOR="$YELLOW" ;;
    *) ICON="$ICON_BATTERY_0"; COLOR="$RED" ;;
esac

if [ -n "$CHARGING" ]; then
    ICON="$ICON_BATTERY_CHARGING"
    COLOR="$GREEN"
fi

sketchybar --set "$NAME" drawing=on icon="$ICON" icon.color="$COLOR" label="${PERCENT}%"
