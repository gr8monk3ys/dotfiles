#!/bin/bash

# front_app_switched delivers the application name in $INFO.

if [ "$SENDER" = "front_app_switched" ]; then
    sketchybar --set "$NAME" label="$INFO"
fi
