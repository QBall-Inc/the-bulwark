#!/bin/bash

WATCH_DIR="${1:-.}"
EVENT_LOG="${EVENT_LOG:-/tmp/watcher-events.log}"
INTERVAL="${INTERVAL:-2}"

if [ ! -d "$WATCH_DIR" ]; then
    echo "Error: Directory not found: $WATCH_DIR" >&2
    exit 1
fi

: > "$EVENT_LOG"

declare -A file_hashes

scan_directory() {
    for file in "$WATCH_DIR"/*; do
        [ -f "$file" ] || continue
        echo "$file"
    done
}

get_hash() {
    md5sum "$1" 2>/dev/null | cut -d' ' -f1
}

check_changes() {
    local current_files=()

    while IFS= read -r file; do
        [ -z "$file" ] && continue
        current_files+=("$file")
        local hash=$(get_hash "$file")
        local basename=$(basename "$file")

        if [ -z "${file_hashes[$file]}" ]; then
            echo "$(date +%s) CREATED $basename" >> "$EVENT_LOG"
            file_hashes[$file]=$hash
        elif [ "${file_hashes[$file]}" != "$hash" ]; then
            echo "$(date +%s) MODIFIED $basename" >> "$EVENT_LOG"
            file_hashes[$file]=$hash
        fi
    done < <(scan_directory)

    for known in "${!file_hashes[@]}"; do
        local found=0
        for current in "${current_files[@]}"; do
            [ "$known" = "$current" ] && found=1 && break
        done
        if [ $found -eq 0 ]; then
            echo "$(date +%s) DELETED $(basename "$known")" >> "$EVENT_LOG"
            unset file_hashes[$known]
        fi
    done
}

echo "Watching: $WATCH_DIR"
echo "Events: $EVENT_LOG"

while true; do
    check_changes
    sleep "$INTERVAL"
done
