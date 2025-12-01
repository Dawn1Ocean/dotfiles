#!/bin/bash

LOCK_FILE="/tmp/clipboard_bridge_lock"

trap "rm -f '$LOCK_FILE'" EXIT

touch "$LOCK_FILE"

types=$(wl-paste --list-types)

if [[ "$types" == *"image/png"* ]]; then
    wl-paste --type image/png | xclip -selection clipboard -t image/png
elif [[ "$types" == *"image/jpeg"* ]]; then
    wl-paste --type image/jpeg | xclip -selection clipboard -t image/jpeg
elif [[ "$types" == *"image/gif"* ]]; then
    wl-paste --type image/gif | xclip -selection clipboard -t image/gif
else
    wl-paste | xclip -selection clipboard
fi

sleep 0.1

rm -f "$LOCK_FILE"
