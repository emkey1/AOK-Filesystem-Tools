#!/usr/bin/env bash

current_dir=$(cd -- "$(dirname -- "$0")" && pwd)

#  shellcheck disable=SC1091
. "$current_dir"/run_as_root.sh
#  shellcheck disable=SC1091
. "$current_dir"/utils.sh # >/dev/null

# destfs_is_alpine && echo "is alpine" || echo "NOT alpine"
# destfs_is_select && echo "is select" || echo "NOT select"
# destfs_is_devuan && echo "is devuan" || echo "NOT devuan"
# destfs_is_debian && echo "is debian" || echo "NOT debian"
# echo "Detected: [$(destfs_detect)]"

echo "Show status for /etc/opt for Host and Dest FS"

echo "Host is: $(hostfs_detect)"
destfs="$(destfs_detect)"
if [[ -n "$destfs" ]]; then
    echo "Dest FS type: $destfs"
fi

if [[ -d "$build_root_d/etc/opt/AOK" ]]; then
    echo "----"
    inspect_files=(
        "deploy_state"
    )
    for rel_fname in "${inspect_files[@]}"; do
        fname="$build_root_d/etc/opt/AOK/$rel_fname"
        if [[ -f "$fname" ]]; then
            echo "$fname  - $(cat "$fname")"
        else
            echo "$fname  <<  missing"
        fi
    done
    echo "----"
    echo
fi

if [[ -n "$build_root_d" ]] && [[ -d "$build_root_d/etc/opt" ]]; then
    echo "=====   Dest FS"
    find "$build_root_d"/etc/opt | tail -n +2
    echo
fi

if [[ "$(find /etc/opt/AOK 2>/dev/null | wc -l)" -gt 1 ]]; then
    echo "=====   Host FS - Nothing should be here!"
    find /etc/opt/AOK | tail -n +2
fi
