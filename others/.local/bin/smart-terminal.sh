#!/bin/bash

if [[ "$XDG_CURRENT_DESKTOP" == *"niri"* ]] || [[ "$XDG_SESSION_DESKTOP" == *"niri"* ]]; then
    exec kitty "${@/--workdir/--directory}"
else
    exec konsole "$@"
fi
