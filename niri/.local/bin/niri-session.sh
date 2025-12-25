#!/bin/bash
export QT_QPA_PLATFORM=wayland
export QT_QPA_PLATFORMTHEME=gtk3
export ELECTRON_OZONE_PLATFORM_HINT=auto
export XDG_MENU_PREFIX=arch-
export http_proxy=http://127.0.0.1:10808
export https_proxy=http://127.0.0.1:10808
export all_proxy=socks5://127.0.0.1:10808

exec niri-session
