#!/bin/bash

HOOK_NAME="$1"  # e.g., "onWallpaperChanged"
HOOK_VALUE="$2" # e.g., "/path/to/wallpaper.jpg"

if [ $HOOK_NAME = "onLightModeChanged" ]; then
    if [ $HOOK_VALUE = "light" ]; then
        niri msg action do-screen-transition -d 600 &
        sed -i 's/^icon_theme=.*/icon_theme=breeze/' ~/.config/qt6ct/qt6ct.conf
    elif [ $HOOK_VALUE = "dark" ]; then
        niri msg action do-screen-transition -d 600 &
        sed -i 's/^icon_theme=.*/icon_theme=breeze-dark/' ~/.config/qt6ct/qt6ct.conf
    fi
fi
