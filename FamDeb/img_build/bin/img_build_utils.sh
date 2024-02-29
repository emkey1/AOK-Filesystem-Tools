#!/bin/sh
# This is sourced. Fake bang-path to help editors and linters
#
#  Part of https://github.com/jaclu/AOK-Filesystem-Tools
#
#  Copyright (c) 2024: Jacob.Lundqvist@gmail.com
#
#  License: MIT
#
#  Common stuff for building Debian/Devuan FS images
#

. /opt/AOK/tools/utils.sh

health_check() {
    msg_1 "Ensure apt is in good health"
    Mapt no_timing
}

update_aok_fs_releae() {
    [ "$1" = "minim" ] && _minim=1
    f_aok_fs_release=/etc/aok-fs-release

    msg_1 "Update $f_aok_fs_release"

    get_lsb_release
    if [ -n "$_minim" ]; then
        aok_fs_type="minim"
    else
        minim_rel="$(cut -d- -f3 "$f_aok_fs_release")"
        aok_fs_type="${minim_rel}-aok"
    fi

    while [ -z "$rel_vers" ]; do
        echo "Enter $f_aok_fs_release vers, what follows $lsb_DistributorID${lsb_Release}-${aok_fs_type}-"
        read -r rel_vers
    done

    if [ -n "$_minim" ]; then
        aok_release="$lsb_DistributorID${lsb_Release}-minim-$rel_vers"
    else
        aok_release="$lsb_DistributorID${lsb_Release}-${aok_fs_type}-$rel_vers"
    fi
    echo "$aok_release" >/"$f_aok_fs_release"
    echo
    echo "$f_aok_fs_release - Set to: $aok_release"
}

rmdir_if_only_uuid() {
    echo "rmdir_if_only_uuid($1)"
    _p="$1"
    [ -z "$_p" ] && error_msg "rmdir_if_only_uuid() - no param"
    [ -d "$_p" ] || error_msg "rmdir_if_only_uuid($_p) - no such dir"

    max_count=1
    [ -f "$_p"/.uuid ] && max_count=2

    if [ "$(find "$_p" | wc -l)" -gt "$max_count" ]; then
        echo
        ls -la "$_p"
        error_msg "$_p contains items other than .uuid!"
    else
        rm -f "$_p"/.uuid
        rmdir "$_p" || error_msg "rmdir failed"
    fi

    # echo "^^^ rmdir_if_only_uuid() - done"
}

ensure_empty_folder() {
    echo "ensure_empty_folder($1)"
    _p="$1"
    [ -z "$_p" ] && error_msg "ensure_empty_folder() - no param"

    if [ "$(find "$_p" | wc -l)" -gt 1 ]; then
        error_msg "$_p not empty"
    fi

    # echo "^^^ ensure_empty_folder() - done"
}

clear_AOK() {
    msg_1 "remove /opt/AOK"
    rm -rf /opt/AOK
    rm -rf /etc/opt/AOK
}

clear_log_tmp() {
    msg_1 "Cleanout log & tmp files"
    rm -rf /var/log/* || error_msg "Failed to clear /var/log"
    rm -rf /tmp/* || error_msg "Failed to clear /tmp"
    rm -rf /var/tmp/* || error_msg "Failed to clear /var/tmp"
}

clear_apt_cache() {
    msg_1 "Remove apt caches"
    rm -rf /var/lib/apt/lists/* || error_msg "Failed to clear /var/lib/apt/lists"
    rm -rf /var/cache/apt/* || error_msg "Failed to clear /var/cache/apt"
    rm -rf /var/cache/debconf/* || error_msg "Failed to clear /var/cache/debconf"
    rm -rf /var/cache/man/* || error_msg "Failed to clear /var/cache/man"
}

remove_aok() {
    #  Since AOK should be gone, error_msg cant be used
    msg_1 "Remove /opt/AOK"
    rm -rf /opt/AOK || {
        echo "ERROR: Failed to clear /opt/AOK"
        exit 1
    }
    rm -rf /etc/opt/AOK || {
        echo "ERROR: Failed to clear /etc/opt/AOK"
        exit 1
    }
}

disable_services() {
    msg_1 "Disable ssh service"
    rc-update del ssh default
}
