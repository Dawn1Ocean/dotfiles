#!/bin/bash

LOCK_FILE="/tmp/clipboard_bridge_lock"

TMP_DIR="/tmp/clipboard_sync_$$"
mkdir -p "$TMP_DIR"
trap "rm -rf '$TMP_DIR'; exit" INT TERM EXIT

COLOR_RESET="\033[0m"
COLOR_GREEN="\033[32m"
COLOR_BLUE="\033[34m"
COLOR_YELLOW="\033[33m"
COLOR_CYAN="\033[36m"

log() {
    local timestamp=$(date '+%H:%M:%S')
    echo -e "${COLOR_CYAN}[$timestamp]${COLOR_RESET} $1"
}

log_sync() {
    local direction=$1
    local type=$2
    local format=$3

    case "$direction" in
        "x11->wl")
            echo -e "${COLOR_CYAN}[$(date '+%H:%M:%S')]${COLOR_RESET} ${COLOR_GREEN}✓${COLOR_RESET} X11 → Wayland | ${COLOR_YELLOW}${type}${COLOR_RESET}${format}"
            ;;
    esac
}

for cmd in xclip wl-copy clipnotify cmp; do
    if ! command -v "$cmd" &> /dev/null; then
        echo "Error: Missing dependency '$cmd'"
        exit 1
    fi
done

echo "Starting X11 -> Wayland sync (Event-driven with clipnotify)..."

clipboard_sync() {
    local current_x11_img="$TMP_DIR/curr_x11.img"
    local current_wl_img="$TMP_DIR/curr_wl.img"
    local last_x11_img="$TMP_DIR/last_x11.img"
    local last_text=""
    
    rm -f "$LOCK_FILE"

    while clipnotify; do
        if [ -f "$LOCK_FILE" ]; then
            sleep 0.2
            continue
        fi
        # ==========================

        sleep 0.05
        img_synced=false

        x11_targets=$(xclip -selection clipboard -t TARGETS -o 2>/dev/null)
        [ -z "$x11_targets" ] && continue

        mime_type=""
        if [[ "$x11_targets" == *"image/png"* ]]; then
            mime_type="image/png"
        elif [[ "$x11_targets" == *"image/jpeg"* ]]; then
            mime_type="image/jpeg"
        elif [[ "$x11_targets" == *"image/gif"* ]]; then
            mime_type="image/gif"
        fi

        if [[ -n "$mime_type" ]]; then
            xclip -selection clipboard -t "$mime_type" -o > "$current_x11_img" 2>/dev/null
            wl-paste -t "$mime_type" > "$current_wl_img" 2>/dev/null
            
            if cmp -s "$current_x11_img" "$current_wl_img"; then
                continue
            fi
            
            if ! cmp -s "$current_x11_img" "$last_x11_img"; then
                wl-copy -t "$mime_type" < "$current_x11_img"
                cp "$current_x11_img" "$last_x11_img"
                log_sync "x11->wl" "Image" " ($mime_type)"
                img_synced=true
            fi
            continue 
        fi

        # -------- Text sync --------
        if [[ "$img_synced" == false ]]; then
            current_text=$(wl-paste --type text/plain 2>/dev/null || true)
            x11_text=$(xclip -selection clipboard -o 2>/dev/null || true)

            if [[ -n "$x11_text" && "$x11_text" != "$last_text" && "$x11_text" != "$current_text" ]]; then
                echo -n "$x11_text" | wl-copy --type text/plain
                last_text="$x11_text"
                
                local preview="${x11_text:0:50}"
                preview="${preview//$'\n'/↵}"
                preview="${preview//$'\r'/}"
                preview="${preview//$'\t'/⇥}"
                [[ ${#x11_text} -gt 50 ]] && preview="${preview}..."
                log_sync "x11->wl" "Text" " \"$preview\""
            fi
        fi
    done
}

log "Clipboard sync service started"
log "Monitoring Wayland ↔ X11 clipboard sync..."

clipboard_sync
