#!/bin/sh
# shellcheck disable=SC2154
#
#  Part of https://github.com/emkey1/AOK-Filesystem-Tools
#
#  License: MIT
#
#  Copyright (c) 2023: Jacob.Lundqvist@gmail.com
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

#
#  Since this is run as /etc/profile during deploy, and this wait is
#  needed for /etc/profile (see Alpine/etc/profile for details)
#  we also put it here
#
sleep 2

if [ ! -d "/opt/AOK" ]; then
    echo "ERROR: This is not an AOK File System!"
    echo
    exit 1
fi

# shellcheck disable=SC1091
. /opt/AOK/tools/utils.sh

tcd_start="$(date +%s)"

#  Ensure important devices are present
msg_2 "Running fix_dev"
/opt/AOK/common_AOK/usr_local_sbin/fix_dev

select_distro

duration="$(($(date +%s) - $tcd_start))"
display_time_elapsed "$duration" "Choose Distro"
