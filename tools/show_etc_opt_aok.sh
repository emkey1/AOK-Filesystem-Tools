#!/usr/bin/env bash

# shellcheck source=/dev/null
hide_run_as_root=1 . /opt/AOK/tools/run_as_root.sh

ensure_ish_or_chrooted

# shellcheck source=/dev/null
. /opt/AOK/tools/utils.sh

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

# shellcheck disable=SC2154
if [[ -d "$d_build_root/etc/opt/AOK" ]]; then
    echo "----"
    inspect_files=(
        "deploy_state"
    )
    for rel_fname in "${inspect_files[@]}"; do
        fname="$d_build_root/etc/opt/AOK/$rel_fname"
        if [[ -f "$fname" ]]; then
            echo "$fname  - $(cat "$fname")"
        else
            echo "$fname  <<  missing"
        fi
    done
    echo "----"
    echo
fi

if [[ -n "$d_build_root" ]] && [[ -d "$d_build_root/etc/opt" ]]; then
    echo "=====   Dest FS"
    find "$d_build_root"/etc/opt | tail -n +2
    echo
fi

if [[ "$(find /etc/opt/AOK 2>/dev/null | wc -l)" -gt 1 ]]; then
    echo "=====   Host FS - Nothing should be here!"
    find /etc/opt/AOK | tail -n +2
fi
