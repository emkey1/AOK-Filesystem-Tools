#!/bin/sh
#
#  Part of https://github.com/jaclu/AOK-Filesystem-Tools
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

#  Allowing this to be run from anywhere using path
current_dir=$(cd -- "$(dirname -- "$0")" && pwd)
AOK_DIR="$(dirname -- "$current_dir")"

# shellcheck source=/opt/AOK/tools/run_as_root.sh
hide_run_as_root=1 . "$AOK_DIR/tools/run_as_root.sh"

# shellcheck source=/opt/AOK/tools/utils.sh
. "$AOK_DIR"/tools/utils.sh

if ! this_is_ish; then
    error_msg "This should only be run on an iSH platform!"
fi

# execute again as root
if [ "$(whoami)" != "root" ]; then
    error_msg "Not executing as root"
fi

echo
echo "Updating /etc/skel files"
echo
rsync_chown "$aok_content"/common_AOK/etc/skel /etc

echo
echo "Upgrading /usr/local/bin & /usr/local/sbin with current items from $aok_content"
echo

#
#  Always copy common stuff
#
echo "Common stuff"
rsync_chown "$aok_content"/common_AOK/usr_local_bin/* /usr/local/bin
rsync_chown "$aok_content"/common_AOK/usr_local_sbin/* /usr/local/sbin

#
#  Copy distro specific stuff
#
if hostfs_is_alpine; then
    echo "Alpine specifics"
    rsync_chown "$aok_content"/Alpine/usr_local_bin/ /usr/local/bin/
    rsync_chown "$aok_content"/Alpine/usr_local_sbin/ /usr/local/sbin/
elif hostfs_is_debian; then
    echo "Debian specifics"
    rsync_chown "$aok_content"/Debian/usr_local_bin/ /usr/local/bin/
    rsync_chown "$aok_content"/Debian/usr_local_sbin/ /usr/local/sbin/
elif hostfs_is_devuan; then
    echo "Devuan specifics"
    rsync_chown "$aok_content"/Devuan/usr_local_bin/ /usr/local/bin/
    rsync_chown "$aok_content"/Devuan/usr_local_sbin/ /usr/local/sbin/
else
    echo "ERROR: Failed to recognize Distro, aborting."
    exit 1
fi
