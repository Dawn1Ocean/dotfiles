#!/bin/bash

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
        "wl->x11")
            echo -e "${COLOR_CYAN}[$(date '+%H:%M:%S')]${COLOR_RESET} ${COLOR_BLUE}✓${COLOR_RESET} Wayland → X11 | ${COLOR_YELLOW}${type}${COLOR_RESET}${format}"
            ;;
    esac
}

check_dependencies() {
    local missing_deps=()
    for cmd in xclip wl-paste wl-copy sha256sum; do
        if ! command -v "$cmd" &>/dev/null; then
            missing_deps+=("$cmd")
        fi
    done

    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        echo "Error: Missing the following dependencies: ${missing_deps[*]}" >&2
        echo "Please install the required packages and try again." >&2
        exit 1
    fi
}

# Debounce variables
last_text=""
last_x11_img_hash=""  # Last image hash synced from X11 to Wayland
last_wl_img_hash=""   # Last image hash synced from Wayland to X11

clipboard_sync() {
    while true; do
        img_synced=false  # Flag indicating if an image has been synced this round

        # -------- Image sync: X11 → Wayland --------
        x11_targets=$(xclip -selection clipboard -t TARGETS -o 2>/dev/null || true)
        x11_img_type=""
        if echo "$x11_targets" | grep -q "image/png"; then
            x11_img_type="image/png"
        elif echo "$x11_targets" | grep -q "image/jpeg"; then
            x11_img_type="image/jpeg"
        elif echo "$x11_targets" | grep -q "image/gif"; then
            x11_img_type="image/gif"
        fi

        if [[ -n "$x11_img_type" ]]; then
            if [[ $(xclip -selection clipboard -t "$x11_img_type" -o 2>/dev/null | wc -c) -gt 0 ]]; then
                x11_img_hash=$(xclip -selection clipboard -t "$x11_img_type" -o 2>/dev/null | sha256sum | awk '{print $1}')

                if [[ -n "$x11_img_hash" && "$x11_img_hash" != "$last_x11_img_hash" ]]; then
                    # Directly transfer image data to Wayland clipboard
                    xclip -selection clipboard -t "$x11_img_type" -o 2>/dev/null | wl-copy -t "$x11_img_type"
                    last_x11_img_hash="$x11_img_hash"
                    last_wl_img_hash="$x11_img_hash"
                    img_synced=true
                    log_sync "x11->wl" "Image" " ($x11_img_type)"
                    # Clear X11 clipboard to make Wayland the sole data source
                    xclip -selection clipboard -i /dev/null
                fi
            fi
        fi

        # -------- Image sync: Wayland → X11 --------
        # Only check Wayland → X11 if no image has been synced this round
        if [[ "$img_synced" == false ]]; then
            wl_types=$(wl-paste --list-types 2>/dev/null || true)
            wl_img_type=""
            if echo "$wl_types" | grep -q "image/png"; then
                wl_img_type="image/png"
            elif echo "$wl_types" | grep -q "image/jpeg"; then
                wl_img_type="image/jpeg"
            elif echo "$wl_types" | grep -q "image/gif"; then
                wl_img_type="image/gif"
            fi

            if [[ -n "$wl_img_type" ]]; then
                # Use a pipe to directly transfer binary data and calculate hash for debounce
                wl_img_hash=$(wl-paste -t "$wl_img_type" 2>/dev/null | tee >(sha256sum | awk '{print $1}' > /tmp/wl_hash_$$) | cat > /dev/null; cat /tmp/wl_hash_$$ 2>/dev/null; rm -f /tmp/wl_hash_$$ 2>/dev/null)

                # If the Wayland image is different from the last sync, sync to X11
                if [[ -n "$wl_img_hash" && "$wl_img_hash" != "$last_wl_img_hash" ]]; then
                    wl-paste -t "$wl_img_type" 2>/dev/null | xclip -selection clipboard -t "$wl_img_type" -i
                    last_wl_img_hash="$wl_img_hash"
                    last_x11_img_hash="$wl_img_hash"
                    img_synced=true  # Flag indicating an image has been synced, skip text sync this round
                    log_sync "wl->x11" "Image" " ($wl_img_type)"
                fi
            fi
        fi

        # -------- Text sync --------
        # Only sync text if no image has been synced this round
        if [[ "$img_synced" == false ]]; then
            current_text=$(wl-paste --type text/plain 2>/dev/null || true)

            # Only read from X11 clipboard if it contains text to avoid warnings from reading binary data
            x11_text=""
            if [[ -z "$x11_img_type" ]]; then
                x11_text=$(xclip -selection clipboard -o 2>/dev/null || true)
            fi

            if [[ -n "$x11_text" && "$x11_text" != "$last_text" && "$x11_text" != "$current_text" ]]; then
                echo -n "$x11_text" | wl-copy --type text/plain
                last_text="$x11_text"
                # Display text preview (up to 50 characters), replace newlines with ↵
                local preview="${x11_text:0:50}"
                preview="${preview//$'\n'/↵}"
                preview="${preview//$'\r'/}"
                preview="${preview//$'\t'/⇥}"
                [[ ${#x11_text} -gt 50 ]] && preview="${preview}..."
                log_sync "x11->wl" "Text" " \"$preview\""
            fi

            if [[ -n "$current_text" && "$current_text" != "$last_text" && "$x11_text" != "$current_text" ]]; then
                echo "$current_text" | xclip -selection clipboard -t UTF8_STRING -i
                last_text="$current_text"
                # Display text preview (up to 50 characters), replace newlines with ↵
                local preview="${current_text:0:50}"
                preview="${preview//$'\n'/↵}"
                preview="${preview//$'\r'/}"
                preview="${preview//$'\t'/⇥}"
                [[ ${#current_text} -gt 50 ]] && preview="${preview}..."
                log_sync "wl->x11" "Text" " \"$preview\""
            fi
        fi

        sleep 0.5
    done
}

trap 'exit' INT TERM EXIT

check_dependencies

log "Clipboard sync service started"
log "Monitoring Wayland ↔ X11 clipboard sync..."

clipboard_sync
