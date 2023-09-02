#!/bin/sh
# This is sourced. Fake bang-path to help editors and linters
#  shellcheck disable=SC2154
#
#  Part of https://github.com/jaclu/AOK-Filesystem-Tools
#
#  License: MIT
#
#  Copyright (c) 2023: Jacob.Lundqvist@gmail.com
#
#  Handling user interactions during deploy of FS
#   - Asking for TZ
#   - Should any external resource be mounted
#
#  This expects to be sourced AFTER utils.sh is sourced, it relies on
#  tools resources to be available!
#

thisfs_is_iCloud_mounted() {
    mount | grep -wq iCloud
}

#===============================================================
#
#   User interactions during deploy
#
#===============================================================

user_interactions() {
    msg_2 "user_interactions()"

    should_icloud_be_mounted

    if [ -z "$AOK_TIMEZONE" ]; then
        msg_1 "Timezone selection"
        "$aok_content"/common_AOK/usr_local_bin/set-timezone
    fi
    # msg_3 "user_interactions()  - done"
}

should_icloud_be_mounted() {
    msg_2 "should_icloud_be_mounted()"

    if ! this_is_ish; then
        msg_3 "This is not iSH, skipping /iCloud mount check"
        return
    fi

    if thisfs_is_iCloud_mounted; then
        msg_3 "was already mounted, returning"
        return
    fi

    # _sibm_dlg_app="dialog"
    _sibm_dlg_app="whiptail"

    if [ -z "$(command -v "$_sibm_dlg_app")" ]; then
        sibm_dependency="$_sibm_dlg_app"
        msg_3 "Installing dependency: $sibm_dependency"

        if [ "$sibm_dependency" = "whiptail" ] && destfs_is_alpine; then
            # whiptail is in package newt in Alpine
            sibm_dependency="newt"
        fi
        if destfs_is_alpine; then
            apk add "$sibm_dependency"
        elif [ -f "$file_debian_version" ]; then
            apt install "$sibm_dependency"
        else
            error_msg "Unrecognized distro, aborting"
        fi
        unset sibm_dependency
    fi

    _sibm_text="Do you want to mount /iCloud now?"
    # --topleft \
    "$_sibm_dlg_app" \
        --title "Mount /iCloud" \
        --yesno "$_sibm_text" 0 0

    _sibm_exitstatus=$?

    if [ "$_sibm_exitstatus" -eq 0 ]; then
        mount -t ios x /iCloud
        msg_1 "/iCloud has been mounted!"
    else
        msg_3 "mount rejected"
    fi

    unset _sibm_dlg_app
    unset _sibm_text
    unset _sibm_exitstatus
    # msg_3 "should_icloud_be_mounted()  done"
}

#===============================================================
#
#   Main
#
#===============================================================

_this_script="user_interactions.sh"

#
#  Argh if this is sourcecd from a login script, like when used by a
#  script masking as /etc/profile $0 will be something like -ash
#  So here the usual basename $0 would fail in such cases
#
_scr_name="$0"
if [ "${_scr_name#-}" != "$_scr_name" ]; then
    _scr_name="${_scr_name#-}"
fi

if [ "$(basename "$_scr_name")" = "$_this_script" ]; then
    echo
    echo "*****  USAGE ERROR  *****"
    echo
    echo "$_this_script can't be run, it is a suport module"
    echo "expected to be sourced from other apps"
    echo
    exit 1
fi

if [ -z "$AOK_VERSION" ]; then
    echo
    echo "*****  USAGE ERROR  *****"
    echo
    echo "$_this_script must be sourced after utils.sh is sourced."
    echo
    exit 1
fi

unset _this_script
unset _scr_name
