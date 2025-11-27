#!/bin/bash

LIGHT_THEME="$HOME/.config/kitty/themes/Light_Default.conf"
DARK_THEME="$HOME/.config/kitty/Default.conf"

function update_all_kitties() {
    local THEME_FILE=$1

    grep -aPo '@mykitty[^\s]*' /proc/net/unix | sort | uniq | while read -r socket_path; do
        # 注意：/proc/net/unix 输出的 @ 对应 abstract socket
        kitty @ --to "unix:$socket_path" set-colors --all --configured "$THEME_FILE" 2>/dev/null
    done
}

current_mode=$(gsettings get org.gnome.desktop.interface color-scheme)

if [[ "$current_mode" == "'prefer-dark'" ]]; then
    update_all_kitties "$DARK_THEME"
else
    update_all_kitties "$LIGHT_THEME"
fi

gsettings monitor org.gnome.desktop.interface color-scheme | while read -r line; do
    if [[ "$line" == *"prefer-dark"* ]]; then
        update_all_kitties "$DARK_THEME"
    else
        update_all_kitties "$LIGHT_THEME"
    fi
done
