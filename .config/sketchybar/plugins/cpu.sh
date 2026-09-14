#!/bin/bash

# Load as a percentage of total capacity.
#
# Deliberately not `top -l 2`, which sleeps a full sampling interval and would
# stall the bar for a second every five. Summing per-process %cpu is a cheap
# read of the same number; dividing by core count turns "800% of one core" on
# an 8-core machine into "100%".

source "$CONFIG_DIR/colors.sh"

CORES="$(sysctl -n hw.ncpu)"
LOAD="$(ps -A -o %cpu | awk -v c="$CORES" 'NR>1 {s += $1} END {printf "%.0f", s / c}')"

COLOR="$GREEN"
if [ "$LOAD" -ge 80 ]; then
    COLOR="$RED"
elif [ "$LOAD" -ge 50 ]; then
    COLOR="$YELLOW"
fi

sketchybar --set "$NAME" label="${LOAD}%" icon.color="$COLOR"
