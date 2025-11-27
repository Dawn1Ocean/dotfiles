#!/bin/bash

dms ipc call theme dark
niri msg action do-screen-transition -d 500 &
sed -i 's/^icon_theme=.*/icon_theme=breeze-dark/' ~/.config/qt6ct/qt6ct.conf
