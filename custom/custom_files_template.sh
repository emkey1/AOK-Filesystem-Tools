#!/usr/bin/env bash
# dummy shebang, helping linters, this file is sourced


#
#  This is a template, If you copy this to /iCloud or other location
#  available for the destination device, you dont have to mess with the
#  git repo
#

file_list=(
    # Each item is (src_file, dest_file, owner)
    # if owner is "" then root:root is used
    ("/iCloud/ish_config/files/etc_hosts" "/etc/hosts" "")
)

#
#  Modify depending on wich device this is deployed to
#
if [[ "$(hostname)" = "JacPad" ]]; then
    file_list+=(
        ("/iCloud/ish_config/files/jacpad/ssh_host_dsa_key"
         "/etc/ssh/ssh_host_dsa_key" "")
        ("/iCloud/ish_config/files/jacpad/ssh_host_dsa_key.pub"
         "/etc/ssh/ssh_host_dsa_key.pub" "")
        ("/iCloud/ish_config/files/jacpad/ssh_host_ecdsa_key"
         "/etc/ssh/ssh_host_dsa_key" "")
        ("/iCloud/ish_config/files/jacpad/ssh_host_ecdsa_key.pub"
         "/etc/ssh/ssh_host_dsa_key.pub" "")
    )
fi
