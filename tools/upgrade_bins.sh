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

if [ ! -d /opt/AOK ]; then
    echo "/opt/AOK missing, this can't continue!"
    exit 1
fi

#  shellcheck disable=SC1091
. /opt/AOK/tools/utils.sh

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
echo "Upgrading /usr/local/bin & /usr/local/sbin with current items from /opt/AOK"
echo

#
#  Always copy common stuff
#
cp -av /opt/AOK/common_AOK/usr_local_bin/* /usr/local/bin
cp -av /opt/AOK/common_AOK/usr_local_sbin/* /usr/local/sbin

#
#  Copy distro specific stuff
#
if is_alpine; then
    cp -av /opt/AOK/Alpine/usr_local_bin/* /usr/local/bin
    cp -av /opt/AOK/Alpine/usr_local_sbin/* /usr/local/sbin
elif is_devuan; then
    cp -av /opt/AOK/Devuan/usr_local_bin/* /usr/local/bin
    cp -av /opt/AOK/Devuan/usr_local_sbin/* /usr/local/sbin
elif is_devuan; then
    cp -av /opt/AOK/Debian/usr_local_bin/* /usr/local/bin
    cp -av /opt/AOK/Debian/usr_local_sbin/* /usr/local/sbin
else
    echo "ERROR: Failed to recognize Distro, aborting."
    exit 1
fi
