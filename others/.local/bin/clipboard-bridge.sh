#!/usr/bin/env bash

RUNTIME_DIR="${XDG_RUNTIME_DIR:-/tmp}"
SYNC_LOCK="$RUNTIME_DIR/clipboard-bridge-${UID}.lock"
SUPERVISOR_LOCK="$RUNTIME_DIR/clipboard-bridge-supervisor-${UID}.lock"
SUPPRESS_FILE="$RUNTIME_DIR/clipboard-bridge-suppress-${UID}"
READ_TIMEOUT="${CLIPBOARD_BRIDGE_READ_TIMEOUT:-2}"
TARGET_SETTLE_DELAY="${CLIPBOARD_BRIDGE_TARGET_SETTLE_DELAY:-0.2}"
TARGET_RETRY_DELAY="${CLIPBOARD_BRIDGE_TARGET_RETRY_DELAY:-0.4}"
IMAGE_RETRY_DELAY="${CLIPBOARD_BRIDGE_IMAGE_RETRY_DELAY:-0.2}"
RESTART_DELAY="${CLIPBOARD_BRIDGE_RESTART_DELAY:-1}"
CLIPNOTIFY_POLL_TIMEOUT=1

if ! command -v readlink >/dev/null 2>&1; then
    printf 'Error: missing dependency readlink\n' >&2
    exit 1
fi
SCRIPT_PATH=$(readlink -f -- "${BASH_SOURCE[0]}") || exit 1

log() {
    printf '[%(%H:%M:%S)T] %s\n' -1 "$*"
}

require_commands() {
    local cmd
    for cmd in "$@"; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            printf 'Error: missing dependency %s\n' "$cmd" >&2
            return 1
        fi
    done
}

image_mime_from_targets() {
    local targets=$1
    if [[ "$targets" == *"image/png"* ]]; then
        printf '%s' 'image/png'
    elif [[ "$targets" == *"image/jpeg"* ]]; then
        printf '%s' 'image/jpeg'
    elif [[ "$targets" == *"image/gif"* ]]; then
        printf '%s' 'image/gif'
    fi
}

content_fingerprint() {
    printf '%s:' "$1"
    sha256sum "$2" | cut -d ' ' -f 1
}

mark_suppressed_content() {
    content_fingerprint "$1" "$2" >"$SUPPRESS_FILE"
}

is_suppressed_content() {
    local expected recorded=""
    expected=$(content_fingerprint "$1" "$2") || return 1

    if [[ -f "$SUPPRESS_FILE" ]]; then
        IFS= read -r recorded <"$SUPPRESS_FILE" || true
        rm -f -- "$SUPPRESS_FILE"
    fi

    [[ "$recorded" == "$expected" ]]
}

sync_wayland_to_x11() {
    local detected_type mime_type payload_size types
    local wl_tmp_file wl_image_file current_x11_file

    require_commands cmp cut file flock grep mktemp mv sha256sum stat timeout wl-paste xclip || return 1

    wl_tmp_file=$(mktemp "$RUNTIME_DIR/clipboard-wltox11.XXXXXX") || return 1
    trap 'rm -f -- "${wl_tmp_file:-}" "${wl_image_file:-}" "${current_x11_file:-}"' RETURN
    wl_image_file=$(mktemp "$RUNTIME_DIR/clipboard-wlimage.XXXXXX") || return 1
    current_x11_file=$(mktemp "$RUNTIME_DIR/clipboard-current-x11.XXXXXX") || return 1

    # wl-paste --watch gives each callback the content belonging to the event
    # on stdin. Consume that snapshot instead of querying the live clipboard
    # again: a clipboard manager may already have replaced the current offer.
    if [[ "${CLIPBOARD_STATE:-data}" != data &&
        "${CLIPBOARD_STATE:-data}" != sensitive ]]; then
        return 0
    fi
    if ! cat >"$wl_tmp_file" || [[ ! -s "$wl_tmp_file" ]]; then
        return 0
    fi

    detected_type=$(file --brief --mime-type -- "$wl_tmp_file") || return 0

    # Screenshot tools often offer both an image and a textual file path.
    # Watch mode may choose that text representation for stdin, so explicitly
    # prefer the live image offer while this callback's selection is current.
    if [[ "$detected_type" != image/* ]] &&
        types=$(timeout "${READ_TIMEOUT}s" wl-paste --list-types 2>/dev/null) &&
        grep -q '^image/' <<<"$types"; then
        if timeout "${READ_TIMEOUT}s" wl-paste --type image \
            >"$wl_image_file" 2>/dev/null && [[ -s "$wl_image_file" ]]; then
            mv -- "$wl_image_file" "$wl_tmp_file"
            detected_type=$(file --brief --mime-type -- "$wl_tmp_file") || return 0
        fi
    fi

    case "$detected_type" in
    image/*)
        mime_type=$detected_type
        ;;
    *)
        mime_type=text/plain
        ;;
    esac
    payload_size=$(stat -c %s -- "$wl_tmp_file") || payload_size=unknown
    log "Wayland event: state=${CLIPBOARD_STATE:-unknown} mime=$mime_type bytes=$payload_size."

    # Clipboard-history selections are real user events and must never be
    # dropped. Capture the event before waiting, then serialize the commit.
    exec 9>"$SYNC_LOCK"
    flock 9 || return 1

    if is_suppressed_content "$mime_type" "$wl_tmp_file"; then
        log "Suppressed bridge echo ($mime_type)."
        return 0
    fi

    # Both Wayland watchers may receive an image offer. The second callback
    # should not replace an already-identical X11 owner and emit another event.
    if [[ "$mime_type" == image/* ]]; then
        timeout "${READ_TIMEOUT}s" xclip -selection clipboard -t "$mime_type" \
            -o 9>&- >"$current_x11_file" 2>/dev/null || : >"$current_x11_file"
    else
        timeout "${READ_TIMEOUT}s" xclip -selection clipboard -o \
            9>&- >"$current_x11_file" 2>/dev/null || : >"$current_x11_file"
    fi
    if cmp -s "$wl_tmp_file" "$current_x11_file"; then
        log "Wayland -> X11 unchanged ($mime_type)."
        return 0
    fi

    # In silent mode xclip reads stdin, forks, and owns the X11 selection until
    # another client replaces it. Do not put that ownership under a timer.
    if [[ "$mime_type" == image/* ]]; then
        if xclip -silent -selection clipboard -t "$mime_type" \
            9>&- <"$wl_tmp_file" 2>/dev/null; then
            log "Wayland -> X11 committed ($mime_type, $payload_size bytes)."
        else
            log "Wayland -> X11 failed ($mime_type)."
            return 1
        fi
    else
        if xclip -silent -selection clipboard \
            9>&- <"$wl_tmp_file" 2>/dev/null; then
            log "Wayland -> X11 committed ($mime_type, $payload_size bytes)."
        else
            log "Wayland -> X11 failed ($mime_type)."
            return 1
        fi
    fi

    # Let clipnotify consume the event generated by xclip while the lock is held.
    sleep 0.15
}

run_x11_to_wayland() {
    local current_x11_img current_wl_img last_x11_img
    local last_text_file current_x11_text current_wl_text
    local x11_targets mime_type notify_status image_ready

    require_commands cmp cp cut flock mktemp sha256sum timeout xclip wl-copy wl-paste clipnotify ||
        return 1

    X11_TMP_DIR=$(mktemp -d "$RUNTIME_DIR/clipboard-sync.XXXXXX") || return 1
    trap 'rm -rf -- "${X11_TMP_DIR:-}"' EXIT
    trap 'exit 0' INT TERM

    current_x11_img="$X11_TMP_DIR/current-x11.img"
    current_wl_img="$X11_TMP_DIR/current-wl.img"
    last_x11_img="$X11_TMP_DIR/last-x11.img"
    last_text_file="$X11_TMP_DIR/last-text"
    current_x11_text="$X11_TMP_DIR/current-x11.txt"
    current_wl_text="$X11_TMP_DIR/current-wl.txt"
    : >"$last_text_file"

    while true; do
        # Periodically return control to Bash so TERM can run its cleanup trap.
        timeout "${CLIPNOTIFY_POLL_TIMEOUT}s" clipnotify
        notify_status=$?
        [[ $notify_status -eq 124 ]] && continue
        [[ $notify_status -ne 0 ]] && return "$notify_status"

        # Do not discard an event just because Wayland -> X11 is still busy.
        # It may be a real user copy that happened during that short window.
        # All operations performed by the peer are timeout-bounded, so waiting
        # here is safe; bridge-generated events become no-ops after comparison.
        exec 9>"$SYNC_LOCK"
        flock 9 || return 1
        # QQ may announce the new X11 owner before its lazy image renderer has
        # finished publishing all TARGETS. A short debounce avoids observing
        # the intermediate text-only state of rich clipboard content.
        sleep "$TARGET_SETTLE_DELAY"

        if ! x11_targets=$(timeout "${READ_TIMEOUT}s" \
            xclip -selection clipboard -t TARGETS -o 7>&- 9>&- 2>/dev/null); then
            flock -u 9
            continue
        fi

        mime_type=$(image_mime_from_targets "$x11_targets")
        if [[ -z "$mime_type" ]]; then
            # QQ can initially advertise only UTF8_STRING, then add an image
            # target while it still owns the selection. Check once more before
            # committing the intermediate text-only clipboard to Wayland.
            sleep "$TARGET_RETRY_DELAY"
            if x11_targets=$(timeout "${READ_TIMEOUT}s" \
                xclip -selection clipboard -t TARGETS -o 7>&- 9>&- 2>/dev/null); then
                mime_type=$(image_mime_from_targets "$x11_targets")
            fi
        fi

        if [[ -n "$mime_type" ]]; then
            log "X11 event: mime=$mime_type."
            image_ready=false
            if timeout "${READ_TIMEOUT}s" \
                xclip -selection clipboard -t "$mime_type" -o \
                7>&- 9>&- >"$current_x11_img" 2>/dev/null &&
                [[ -s "$current_x11_img" ]]; then
                image_ready=true
            else
                # The first request can be what makes QQ render the image.
                # Retry once, still with a hard timeout on both attempts.
                sleep "$IMAGE_RETRY_DELAY"
                if timeout "${READ_TIMEOUT}s" \
                    xclip -selection clipboard -t "$mime_type" -o \
                    7>&- 9>&- >"$current_x11_img" 2>/dev/null &&
                    [[ -s "$current_x11_img" ]]; then
                    image_ready=true
                fi
            fi

            if [[ "$image_ready" == true ]]; then
                if ! timeout "${READ_TIMEOUT}s" wl-paste --type "$mime_type" \
                    7>&- 9>&- >"$current_wl_img" 2>/dev/null; then
                    : >"$current_wl_img"
                fi

                if ! cmp -s "$current_x11_img" "$current_wl_img" &&
                    ! cmp -s "$current_x11_img" "$last_x11_img"; then
                    mark_suppressed_content "$mime_type" "$current_x11_img"
                    if timeout "${READ_TIMEOUT}s" wl-copy --type "$mime_type" \
                        7>&- 9>&- <"$current_x11_img" 2>/dev/null; then
                        cp -- "$current_x11_img" "$last_x11_img"
                        log "X11 -> Wayland committed ($mime_type)."
                    else
                        rm -f -- "$SUPPRESS_FILE"
                    fi
                fi
            fi
            flock -u 9
            continue
        fi

        log 'X11 event: mime=text/plain.'

        if ! timeout "${READ_TIMEOUT}s" xclip -selection clipboard -o \
            7>&- 9>&- >"$current_x11_text" 2>/dev/null; then
            flock -u 9
            continue
        fi

        if ! timeout "${READ_TIMEOUT}s" wl-paste --no-newline --type text/plain \
            7>&- 9>&- >"$current_wl_text" 2>/dev/null; then
            : >"$current_wl_text"
        fi

        if [[ -s "$current_x11_text" ]] &&
        ! cmp -s "$current_x11_text" "$last_text_file" &&
        ! cmp -s "$current_x11_text" "$current_wl_text"; then
            mark_suppressed_content text/plain "$current_x11_text"
            if timeout "${READ_TIMEOUT}s" wl-copy --type text/plain \
                7>&- 9>&- <"$current_x11_text" 2>/dev/null; then
                cp -- "$current_x11_text" "$last_text_file"
                log 'X11 -> Wayland committed (text/plain).'
            else
                rm -f -- "$SUPPRESS_FILE"
            fi
        fi

        flock -u 9
    done
}

run_supervisor() {
    local text_watch_pid="" image_watch_pid="" x11_pid="" worker_status

    require_commands flock wl-paste || return 1

    exec 7>"$SUPERVISOR_LOCK"
    if ! flock -n 7; then
        printf 'Clipboard bridge is already running.\n' >&2
        return 0
    fi

    rm -f -- "$SUPPRESS_FILE"

    stop_workers() {
        [[ -n "$text_watch_pid" ]] && kill "$text_watch_pid" 2>/dev/null || true
        [[ -n "$image_watch_pid" ]] && kill "$image_watch_pid" 2>/dev/null || true
        [[ -n "$x11_pid" ]] && kill "$x11_pid" 2>/dev/null || true
        [[ -n "$text_watch_pid" ]] && wait "$text_watch_pid" 2>/dev/null || true
        [[ -n "$image_watch_pid" ]] && wait "$image_watch_pid" 2>/dev/null || true
        [[ -n "$x11_pid" ]] && wait "$x11_pid" 2>/dev/null || true
        text_watch_pid=""
        image_watch_pid=""
        x11_pid=""
    }

    shutdown() {
        trap - INT TERM EXIT
        stop_workers
        exit 0
    }

    trap shutdown INT TERM EXIT
    log 'Starting Wayland <-> X11 clipboard bridge.'

    while true; do
        # Generic MIME inference can skip image-only offers when stdout has no
        # filename. Keep a dedicated image watcher alongside the text watcher.
        wl-paste --watch "$SCRIPT_PATH" wl-to-x11 7>&- &
        text_watch_pid=$!

        wl-paste --type image --watch "$SCRIPT_PATH" wl-to-x11 7>&- &
        image_watch_pid=$!

        (exec 7>&-; run_x11_to_wayland) &
        x11_pid=$!

        # Both directions form one service. Restart all workers if one dies.
        wait -n "$text_watch_pid" "$image_watch_pid" "$x11_pid" 2>/dev/null
        worker_status=$?
        log "A clipboard worker exited (status $worker_status); restarting all workers."
        stop_workers
        sleep "$RESTART_DELAY"
    done
}

case "${1:-supervisor}" in
wl-to-x11)
    sync_wayland_to_x11
    ;;
supervisor)
    run_supervisor
    ;;
*)
    printf 'Usage: %s [supervisor|wl-to-x11]\n' "${0##*/}" >&2
    exit 2
    ;;
esac
