#!/bin/bash

# volume_change delivers the new level in $INFO. On load there is no event
# yet, so fall back to asking CoreAudio once.

source "$CONFIG_DIR/colors.sh"
source "$CONFIG_DIR/icons.sh"

VOLUME="$INFO"
if [ -z "$VOLUME" ]; then
    VOLUME="$(osascript -e 'output volume of (get volume settings)' 2>/dev/null)"
    [ "$(osascript -e 'output muted of (get volume settings)' 2>/dev/null)" = "true" ] && VOLUME=0
fi
[ -z "$VOLUME" ] && exit 0

case "$VOLUME" in
    0) ICON="$ICON_VOLUME_MUTE" ;;
    [1-9] | [1-3][0-9]) ICON="$ICON_VOLUME_LOW" ;;
    [4-6][0-9]) ICON="$ICON_VOLUME_MED" ;;
    *) ICON="$ICON_VOLUME_HIGH" ;;
esac

sketchybar --set "$NAME" icon="$ICON" label="${VOLUME}%"
