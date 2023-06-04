#!/usr/bin/env bash
# dummy shebang, helping linters, this file is sourced

#
#  This is a template, If you copy this to /iCloud or other location
#  available on the destination device, you dont have to mess with the
#  git repo
#
# Each item is: src_file dest_file owner
# if owner is "" then owner is not set
#
#  shellcheck disable=SC2034
file_list=(
    /iCloud/deploy/files/etc_hosts /etc/hosts root:
)

#
#  Modify depending on wich device this is deployed to
#
if [[ "$(hostname)" = "JacPad" ]]; then
    file_list+=(
        /iCloud/deploy/files/jacpad/ssh_host_dsa_key /etc/ssh/ssh_host_dsa_key root:
    )
fi
