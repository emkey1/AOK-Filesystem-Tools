#!/bin/sh
#
#  Part of https://github.com/emkey1/AOK-Filesystem-Tools
#
#  License: MIT
#
#  Copyright (c) 2022: Jacob.Lundqvist@gmail.com
#
#  Version: 1.3.5  2022-08-21
#
#  Intended usage is for small systems where a cron might not be running and or
#  needing to do some sanity checks after booting.
#
#  Trigger this in /etc/inittab by adding a line:
#
#  ::once:/usr/local/bin/post_boot.sh
#
#  In the case of AOK
#    * there are some first-run tasks that need to be done
#    * services sometimes fail to start by init, restarting them here
#      tends to help
#
#  Global shellcheck settings:
# shellcheck disable=SC2154

post_boot_log=/var/log/post_boot.log

# aok_content="/opt/AOK"
# if [ -f "$aok_content"/BUILD_ENV ]; then
#     # shellcheck disable=SC1091
#     . "$aok_content"/BUILD_ENV
# else
#     echo
#     echo "ERROR: /usr/local/sbin/post_boot.sh Could not find $aok_content/BUILD_ENV"
#     echo "       This should never happen..."
#     echo
# fi

respawn_it() {
    tmp_log_file="/tmp/post_boot-$$"

    $0 will_run > "$tmp_log_file" 2>&1

    # only keep tmp log if not empty
    log_size="$(/bin/ls -s "$tmp_log_file" | awk '{ print $1 }')"
    if [ "$log_size" -ne 0 ]; then
        echo "---  $(date) ($$)  ---" >> "$post_boot_log"
        cat "$tmp_log_file" >> "$post_boot_log"
    fi
    rm "$tmp_log_file"
    # shellcheck disable=SC2317
    exit 0
}


#
#  If run with no parameters, respawn with output going to $post_boot_log,
#  all to be inittab friendly.
#
if [ -z "$1" ]; then
    echo "with no param this is re-spawned, logging to: $post_boot_log:"
    respawn_it
    # shellcheck disable=SC2317
    exit 0
fi


if [ ! -e /etc/opt/AOK/is_chrooted ]; then
    # Don't bother if chrooted
    /usr/local/bin/fix_dev
fi


# The following is needed for upstream PR #1716
if [ ! -L /dev/fd ]; then
    echo "--  Adding /dev/fd  --"
    ln -sf /proc/self/fd /dev/fd
fi


#  Update motd to indicate current env
/usr/local/sbin/update_motd


#
#  Add dcron if not done so already, typically a first boot task
#
if ! rc-status | grep -q dcron ; then
    echo "--  Adding service dcron  --"
    rc-update add dcron
    rc-service dcron restart
fi


#
#  Restart all services not in started state, should not be needed normally
#  but here we are, and if they are already running, nothing will happen.
#
/usr/local/bin/do_fix_services
