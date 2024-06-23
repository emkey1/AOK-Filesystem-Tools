#!/bin/sh
#
#  Part of https://github.com/jaclu/AOK-Filesystem-Tools
#
#  License: MIT
#
#  Copyright (c) 2024: Jacob.Lundqvist@gmail.com
#
#  setup_devuan.sh
#
#  This modifies a Devuan Linux FS with the AOK changes
#

prepare_env_etc() {
    msg_2 "prepare_env_etc() - Replacing a few /etc files"

    #
    #  Most of the Debian services, mounting fs, setting up networking etc
    #  serve no purpose in iSH, since all this is either handled by iOS
    #  or done by the app before bootup
    #
    msg_3 "Disabling previous openrc runlevel tasks"
    rm /etc/runlevels/*/* -f

    msg_3 "Adding env versions & AOK Logo to /etc/update-motd.d"
    mkdir -p /etc/update-motd.d
    rsync_chown /opt/AOK/FamDeb/etc/update-motd.d /etc

    _f=/etc/skel/.bash_logout
    [ -f "$_f" ] && {
        msg_3 "Removing $_f to prevent clear screen"
        rm "$_f"
        _f=/root/.bash_logout
        msg_4 "Remove (potentially) already present $_f"
        rm -f "$_f"
    }

    msg_3 "prepare_env_etc() done"
}

handle_apts() {
    #
    #  Not normally needed, unless /var/cache/apt had been cleared,
    #  so in this case, better safe than sorry
    #
    msg_1 "apt update"
    apt update -y

    msg_1 "apt upgrade"
    apt upgrade -y || {
        error_msg "apt upgrade failed"
    }

    if destfs_is_debian; then
        apts_to_add="$DEB_PKGS"
        apts_to_remove="$DEB_PKGS_SKIP"
        distro_name="Debian"
    else
        apts_to_add="$DEVU_PKGS"
        apts_to_remove="$DEVU_PKGS_SKIP"
        distro_name="Devuan"
    fi

    if [ -n "$apts_to_add" ]; then
        msg_1 "Add $distro_name packages"
        echo "$apts_to_add"
        echo
        #  shellcheck disable=SC2086
        apt install -y $apts_to_add || {
            error_msg "apt install failed"
        }
        msg_1 "Ensure apt is in good health"
        Mapt || error_msg "Mapt reported error"
    fi

    if [ -n "$apts_to_remove" ]; then
        msg_1 "Removing $distro_name packages"
        echo "$apts_to_remove"
        echo
        #
        #  To prevent leftovers having to potentially be purged later
        #  we do purge instead of remove, purge implies a remove
        #
        #  shellcheck disable=SC2086
        apt purge -y $apts_to_remove || {
            error_msg "apt purge failed"
        }
        msg_1 "Ensure apt is in good health"
        Mapt || error_msg "Mapt reported error after purge"
    fi
}

#===============================================================
#
#   Main
#
#===============================================================

[ -z "$d_aok_etc" ] && . /opt/AOK/tools/utils.sh

ensure_ish_or_chrooted

#
#  Common deploy, used both for all distros
#
$setup_common_aok || error_msg "in $setup_common_aok"

msg_script_title "setup_famdeb.sh  Common setup steps for Debian based distros"

msg_3 "Create /var/log/wtmp"
touch /var/log/wtmp

prepare_env_etc
handle_apts

msg_3 "Create /var/log/wtmp"
touch /var/log/wtmp

Mapt || error_msg "Mapt reported error"

#
#  Our
#
rsync_chown /opt/AOK/FamDeb/etc/init.d/rc /etc/init.d silent

#  Ensure that login is required
rsync_chown /opt/AOK/FamDeb/etc/pam.d/common-auth /etc/pam.d silent
