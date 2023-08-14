#!/bin/sh
# shellcheck disable=SC2154
#
#  Part of https://github.com/emkey1/AOK-Filesystem-Tools
#
#  License: MIT
#
#  Copyright (c) 2023: Jacob.Lundqvist@gmail.com
#
#  select_distro.sh
#
#  Setup Distro choice
#

select_distro() {
    text="
Alpine is the regular AOK FS, fully stable.

Debian is version 10 (Buster). It was end of lifed 2022-07-18 and is
thus now unmaintained except for security updates.
It should be fine for testing Debian with the AOK FS extensions under iSH-AOK.

Devuan is still experimental. It has DNS issues, enough is in /etc/hosts
for basic apt actions

Only iSH-AOK is known to be able to run Debian/Devuan, for other iSH
Alpine is the safe bet.

Select distro:
 1 - Alpine $ALPINE_VERSION
 2 - Debian 10
 3 - Devuan 4
"
    echo
    echo "$text"
    read -r selection
    echo
    case "$selection" in

    1)
        echo "Alpine selected"
        echo
        msg_1 "running $setup_alpine_scr"
        rm -f "$destfs_select_hint"
        "$setup_alpine_scr"
        ;;

    2)
        echo "Debian selected"
        test -f "$additional_tasks_script" && notification_additional_tasks
        "$aok_content"/choose_distro/install_debian.sh
        ;;

    3)
        echo "Devuan selected"
        test -f "$additional_tasks_script" && notification_additional_tasks
        "$aok_content"/choose_distro/install_devuan.sh
        ;;

    *)
        echo "*****   Invalid selection   *****"
        sleep 1
        select_distro
        ;;

    esac
}

#===============================================================
#
#   Main
#
#===============================================================

tcd_start="$(date +%s)"

#
#  Ensure important devices are present.
#  this is not yet in inittab, so run it from here on 1st boot
#
echo "-->  Running fix_dev  <--"
/opt/AOK/common_AOK/usr_local_sbin/fix_dev ignore_init_check
echo

# shellcheck disable=SC1091
. /opt/AOK/tools/utils.sh

manual_runbg

#  shellcheck disable=SC2009
if ! this_fs_is_chrooted && ! ps ax | grep -v grep | grep -qw cat; then
    cat /dev/location >/dev/null &
    msg_1 "iSH now able to run in the background"
fi

select_distro

duration="$(($(date +%s) - tcd_start))"
display_time_elapsed "$duration" "Choose Distro"

#
#  Mostly needed in case nav_keys.sh or some other config task
#  would be run before the first re-boot
#
export PATH=/usr/local/sbin:/usr/local/bin:/sbin:/usr/sbin:/bin:/usr/bin
