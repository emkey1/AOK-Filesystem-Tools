#!/bin/sh
#
#  Version: 1.3.1  2022-06-15
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

post_boot_log=/tmp/post_boot.log

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

    exit 0
}


#
#  If run with no parameters, respawn with output going to $post_boot_log,
#  all to be inittab friendly
#
if [ "$1" = "" ]; then
    echo "with no param this is respawned, logging to: $post_boot_log:"
    respawn_it
    exit 0
fi


#
#  /dev/null gets screwed up at times.
#  Recreate if it needs fixing.
#
# shellcheck disable=SC2010
if ! ls -l /dev/null | grep -q "root root 1, 3"; then
    dev_null_fix_log="/tmp/dev_null_fix.log"
    echo "Bad /dev/null"
    ls -l /dev/null
    #
    #  Depending on the nature of the /deb/null issue
    #  and since this scripts output is captured in a log file
    #  The /dev/null issue might cause the logging of the fix
    #  not to happen... Weird but I havent found away arround this
    #
    rm /dev/null > "$dev_null_fix_log" 2>&1
    mknod /dev/null c 1 3 >> "$dev_null_fix_log" 2>> "$dev_null_fix_log"
    chmod 666 /dev/null >> "$dev_null_fix_log" 2>> "$dev_null_fix_log"

    # only keep fix log if not empty
    log_size="$(/bin/ls -s "$dev_null_fix_log" | awk '{ print $1 }')"
    if [ "$log_size" -eq 0 ]; then
        rm "$dev_null_fix_log"
    fi

    echo "Fixed /dev/null"

    #
    #  Since /dev/null was recreated respawn this (again),
    #  in order for the redirects used on this script to work
    #  all logging up this point likely didn't happen.
    #
    respawn_it
    exit 0
fi


# The following is needed for upstream PR #1716
if [ ! -h /dev/fd ]; then
    ln -sf /proc/self/fd /dev/fd
fi


if [ -e /etc/FIRSTBOOT ]; then

    # Start a couple of services
    rc-update add dcron
    rc-service dcron restart
    rc-update add runbg
    rc-service runbg restart

    echo "FIRSTBOOT tasks done"
    rm /etc/FIRSTBOOT # Only do this stuff once, so remove the file now
fi


# /etc/init.d/networking keeps getting an extra } written at the end
# For some unknown reason.  Overwrite it when we login to hopefully
# mitigate that
#cp /root/init.d/networking /etc/init.d


#
#  Restart all services not in started state, should not be needed normally
#  but here we are, and if they are already running, nothing will happen.
#
/usr/local/bin/do_fix_services
