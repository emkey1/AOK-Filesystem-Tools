#!/usr/bin/env bash
# dummy shebang, helping linters, this file is sourced

#
#  This is a template, It needs to be located so that both this, and
#  any files listed below can be accessed on first boot on destination
#  device, so typically inside /iCloud
#
# Each item is: src_file dest_file owner
# if owner is "" then owner is not set
#  owner: is a shorthand for setting group id to the users default group
#  owner:group  gives full control over ownership settings
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
