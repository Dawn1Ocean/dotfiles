#!/bin/bash
INIT_FLAG="/tmp/dms_theme_initialized"

try_restart_dms() {
    dms restart
    sleep 0.2
    dms ipc call theme dark
}

sed -i 's/^icon_theme=.*/icon_theme=breeze-dark/' ~/.config/qt6ct/qt6ct.conf

niri msg action do-screen-transition -d 2500 &
sleep 0.01

if [ ! -f "$INIT_FLAG" ]; then
    try_restart_dms
    try_restart_dms
    touch "$INIT_FLAG"
else
    try_restart_dms
fi
