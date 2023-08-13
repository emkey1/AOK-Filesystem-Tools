#!/usr/bin/env bash

current_dir=$(cd -- "$(dirname -- "$0")" && pwd)
#  shellcheck disable=SC1091
. "$current_dir"/utils.sh

#  shellcheck disable=SC2154
ls -lR "$build_root_d"/etc/opt

inspect_files=(
    "deploy_state"
)

echo
for rel_fname in "${inspect_files[@]}"; do
    fname="$build_root_d/etc/opt/AOK/$rel_fname"
    if [[ -f "$fname" ]]; then
        echo "$fname  - $(cat "$fname")"
    else
        echo "$fname  <<  missing"
    fi
done

echo
ls -lR /etc/opt
