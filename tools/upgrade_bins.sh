#!/bin/sh
# shellcheck disable=SC2154

#
#  Part of https://github.com/emkey1/AOK-Filesystem-Tools
#
#  License: MIT
#
#  Copyright (c) 2023: Jacob.Lundqvist@gmail.com
#
#  upgrades /usr/local/bin & /usr/local/sbin with latest versions
#  from /opt/AOK, both common and distro based items
#

#===============================================================
#
#   Main
#
#===============================================================

current_dir=$(cd -- "$(dirname -- "$0")" && pwd)
#  shellcheck disable=SC1091
. "$current_dir"/utils.sh

if ! is_ish; then
    error_msg "This should only be run on an iSH platform!"
fi

# execute again as root
if [ "$(whoami)" != "root" ]; then
    echo "Executing as root"
    # using $0 instead of full path makes location not hardcoded
    if ! sudo "$0" "$@"; then
        echo
        echo "ERROR: Failed to sudo $0"
        echo
    fi
    exit 0
fi

echo
echo "Upgrading /usr/local/bin & /usr/local/sbin with current items from $aok_content"
echo

#
#  Always copy common stuff
#
rsync -ahP "$aok_content"/common_AOK/usr_local_bin/* /usr/local/bin
rsync -ahP "$aok_content"/common_AOK/usr_local_sbin/* /usr/local/sbin

#
#  Copy distro specific stuff
#
if is_alpine; then
    rsync -ahP "$aok_content"/Alpine/usr_local_bin/* /usr/local/bin
    rsync -ahP "$aok_content"/Alpine/usr_local_sbin/* /usr/local/sbin
elif is_devuan; then
    rsync -ahP "$aok_content"/Devuan/usr_local_bin/* /usr/local/bin
    rsync -ahP "$aok_content"/Devuan/usr_local_sbin/* /usr/local/sbin
elif is_debian; then
    rsync -ahP "$aok_content"/Debian/usr_local_bin/* /usr/local/bin
    rsync -ahP "$aok_content"/Debian/usr_local_sbin/* /usr/local/sbin
else
    echo "ERROR: Failed to recognize Distro, aborting."
    exit 1
fi
