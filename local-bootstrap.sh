#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CACHE_FILE="$SCRIPT_DIR/.latest-save"
ROLES=("quarry" "manager" "runner")

if [[ "${1:-}" == "--set-save" ]]; then
    NEW_ROOT="$2"
    if [[ ! -d "$NEW_ROOT" ]]; then
        echo "Error: '$NEW_ROOT' is not a directory" >&2
        exit 1
    fi
    echo "$NEW_ROOT" >"$CACHE_FILE"
    echo "Save folder set to: $NEW_ROOT"
    exit 0
fi

ROLE="$1"
TARGET_ID="$2"

if [[ ! -f "$CACHE_FILE" ]]; then
    echo "Error: Save cache file doesn't exist. Run: $0 --set-save <SAVE_DIR>" >&2
    exit 1
fi

SAVE_DIR="$(cat "$CACHE_FILE")"
TARGET_DIR="$SAVE_DIR/computercraft/computer/$TARGET_ID"

if [[ -z "$TARGET_DIR" || ! -d "$TARGET_DIR" ]]; then
    mkdir -p "$TARGET_DIR"
fi

role_valid=false
for r in "${ROLES[@]}"; do
    if [[ "$r" == "$ROLE" ]]; then
        role_valid=true
        break
    fi
done

if [[ "$role_valid" == false ]]; then
    echo "Error: Role '$ROLE' is not supported" >&2
    exit 1
fi

case "$ROLE" in
    quarry|runner)
        SOURCES=("$ROLE" "lib" "wireless" "movement")
        ;;
    manager)
        SOURCES=("$ROLE" "lib" "wireless" "display")
        ;;
esac

for src in "${SOURCES[@]}"; do
    while IFS= read -r -d '' file; do
        if [[ "$src" == "$ROLE" ]]; then
            rel="${file#"$src/"}"
        else
            rel="$file"
        fi

        target_path="$TARGET_DIR/$rel"
        mkdir -p "$(dirname "$target_path")"

        link_target="$(realpath --relative-to="$(dirname "$target_path")" "$file")"

        if [[ -e "$target_path" ]]; then
            if [[ -L "$target_path" ]]; then
                rm "$target_path"
            else
                echo "Error: '$target_path' exists and is not a symlink" >&2
                exit 1
            fi
        fi

        ln -s "$(realpath "$file")" "$target_path"
        echo "Linked: $(realpath "$file") -> $target_path"
    done < <(find "$src" -type f -print0)
done
