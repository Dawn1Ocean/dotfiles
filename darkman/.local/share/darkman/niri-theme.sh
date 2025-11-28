#!/bin/bash

case "$1" in
    dark)
        dms ipc call theme dark
        sed -i 's/^icon_theme=.*/icon_theme=breeze-dark/' ~/.config/qt6ct/qt6ct.conf
        ;;
    light)
        dms ipc call theme light
        sed -i 's/^icon_theme=.*/icon_theme=breeze/' ~/.config/qt6ct/qt6ct.conf
        ;;
    *)
        echo "Usage: $0 {dark|light}"
        exit 1
        ;;
esac

niri msg action do-screen-transition -d 500 &
