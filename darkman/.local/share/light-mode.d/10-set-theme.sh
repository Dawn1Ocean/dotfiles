#!/bin/bash

dms ipc call theme light
niri msg action do-screen-transition -d 500 &
sed -i 's/^icon_theme=.*/icon_theme=breeze/' ~/.config/qt6ct/qt6ct.conf
