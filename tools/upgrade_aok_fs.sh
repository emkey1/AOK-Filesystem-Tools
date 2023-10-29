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

deploy_stuff() {
    msg_2 "deploy_stuff()"
    source="$1"
    d_dest="$2"

    [ -z "$source" ] && error_msg "deploy_stuff() no source param"
    [ -z "$d_dest" ] && error_msg "deploy_stuff() no dest param"

    rsync -ahP "$source" "$d_dest"
    # Fix ownership, since repo most likely is owned by a user
    chown -R root: "$d_dest"

    unset source
    unset d_dest
    # msg_3 "deploy_stuff() - done"
}

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
deploy_stuff "$aok_content"/common_AOK/etc/skel /etc

echo
echo "Upgrading /usr/local/bin & /usr/local/sbin with current items from $aok_content"
echo

#
#  Always copy common stuff
#
echo "Common stuff"
deploy_stuff "$aok_content"/common_AOK/usr_local_bin/* /usr/local/bin
deploy_stuff "$aok_content"/common_AOK/usr_local_sbin/* /usr/local/sbin

#
#  Copy distro specific stuff
#
if hostfs_is_alpine; then
    echo "Alpine specifics"
    deploy_stuff "$aok_content"/Alpine/usr_local_bin/* /usr/local/bin
    deploy_stuff "$aok_content"/Alpine/usr_local_sbin/* /usr/local/sbin
elif hostfs_is_debian; then
    echo "Debian specifics"
    deploy_stuff "$aok_content"/Debian/usr_local_bin/* /usr/local/bin
    deploy_stuff "$aok_content"/Debian/usr_local_sbin/* /usr/local/sbin
elif hostfs_is_devuan; then
    echo "Devuan specifics"
    deploy_stuff "$aok_content"/Devuan/usr_local_bin/* /usr/local/bin
    deploy_stuff "$aok_content"/Devuan/usr_local_sbin/* /usr/local/sbin
else
    echo "ERROR: Failed to recognize Distro, aborting."
    exit 1
fi
