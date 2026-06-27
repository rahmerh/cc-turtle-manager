#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CACHE_FILE="$SCRIPT_DIR/.latest-save"
ROLES=("quarry" "manager" "runner")

if [[ "$1" == "--set-save" ]]; then
    NEW_ROOT="$2"

    if [[ ! -d "$NEW_ROOT" ]]; then
        echo "Error: '$NEW_ROOT' is not a directory" >&2
        exit 1
    fi

    echo "$NEW_ROOT" >"$CACHE_FILE"
    echo "Save folder set to: $NEW_ROOT"
    exit 0
fi

role="$1"
computer_id="$2"

if [[ ! -f "$CACHE_FILE" ]]; then
    echo "Error: Save cache file doesn't exist. Run: $0 --set-save <SAVE_DIR>" >&2
    exit 1
fi

save_dir="$(cat "$CACHE_FILE")"
computer_target_dir="$save_dir/computercraft/computer/$computer_id"

if [[ -z "$computer_target_dir" || ! -d "$computer_target_dir" ]]; then
    mkdir -p "$computer_target_dir"
fi

role_valid=false
for r in "${ROLES[@]}"; do
    if [[ "$r" == "$role" ]]; then
        role_valid=true
        break
    fi
done

if [[ "$role_valid" == false ]]; then
    echo "Error: Role '$role' is not supported" >&2
    exit 1
fi

case "$role" in
    quarry | runner)
        scripts_to_link=("$role" "lib" "wireless" "movement")
        ;;
    manager)
        scripts_to_link=("$role" "lib" "wireless" "display")
        ;;
esac

for src in "${scripts_to_link[@]}"; do
    while IFS= read -r -d '' file; do
        if [[ "$src" == "$role" ]]; then
            rel="${file#"$src/"}"
        else
            rel="$file"
        fi

        target_path="$computer_target_dir/$rel"
        mkdir -p "$(dirname "$target_path")"

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
