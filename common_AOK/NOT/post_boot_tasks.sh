#!/bin/sh
#
#  Part of https://github.com/emkey1/AOK-Filesystem-Tools
#
#  License: MIT
#
#  Copyright (c) 2023: Jacob.Lundqvist@gmail.com
#
#  This runs post boot tasks, normally used during deploy, but could
#  be used for other purposes.
#

calculate_checksum() {
    md5sum "$aok_post_boot_task" 2>/dev/null | awk '{ print $1 }'
}

aok_post_boot_task="/opt/aok_post_boot_task"

if [ -x "$aok_post_boot_task" ]; then
    #
    #  When some post-boot task needs to happen after a reboot
    #  touch /opt/post_boot_done
    #  If this file is pressent, no more post-boot tasks will be done now
    #  and system will be rebooted.
    #  This is used for Alpine pre-builds, when the last step of removing
    #  apks only usable on iSH-AOK kernels should not be done during
    #  the pre-build. It should happen at the target device.
    #
    rm -f /opt/post_boot_done

    while [ -x "$aok_post_boot_task" ] && [ ! -f /opt/post_boot_done ]; do
        echo "*** will run: $aok_post_boot_task"
        #
        #  During its run the script should have either removed itself
        #  or pointed it to another script.
        #  If it is unchanged, there was an error. In this case abort
        #  the loop to avoid running the same script repeatedly, possibly
        #  for ever.
        #
        chksm_pb_task="$(calculate_checksum)"
        "$aok_post_boot_task"
        post_chksm_pb_task="$(calculate_checksum)"
        if [ "$chksm_pb_task" = "$post_chksm_pb_task" ]; then
            echo
            echo "ERROR: /opt/aok_post_boot_task unchanged, aborting"
            echo "It should either delete itself or"
            echo "be replaced with another script"
            echo "to avoid endless repeats"
            echo
            break
        fi
    done

    rm -f /opt/post_boot_done

    #
    #  exit will typically trigger an instant reboot, this gives a
    #  moment to Ctrl-C if one wants to read
    #
    if [ -f /etc/opt/AOK/is_chrooted ]; then
        echo "***  processing $aok_post_boot_task completed, exiting chroot"
        echo
    else
        echo "***  /etc/profile completed post-boot tasks, please reboot now"
        /bin/sh
        exit 1
    fi
    exit 1
fi
