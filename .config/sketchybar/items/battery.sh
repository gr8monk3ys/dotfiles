#!/bin/bash

# Battery charge (right side). Polls slowly and also wakes on the power
# source changing, which is when it actually matters.

sketchybar --add item battery right \
    --set battery \
        update_freq=120 \
        script="$PLUGIN_DIR/battery.sh" \
    --subscribe battery power_source_change system_woke
