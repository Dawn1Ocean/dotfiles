#!/bin/bash
#!/bin/bash

case "$1" in
    dark)
        dms ipc call theme dark
        gsettings set org.gnome.desktop.interface icon-theme 'breeze-dark'
        ;;
    light)
        dms ipc call theme light
        gsettings set org.gnome.desktop.interface icon-theme 'breeze'
        ;;
    *)
        echo "Usage: $0 {dark|light}"
        exit 1
        ;;
esac

niri msg action do-screen-transition -d 500 &
