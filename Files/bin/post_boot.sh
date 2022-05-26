#!/bin/sh
#
#  Version: 1.2.1  2022-05-25
#
#  Intended usage is for small systems where a cron might not be running and or
#  needing to do some sanity checks after booting.
#
#  Trigger this in /etc/inittab by adding a line:
#
#  ::wait:/usr/local/bin/post_boot.sh
#
#  Before starting /sbin/openrc or similar
#
#  In the case of AOK
#    * there are some first-run tasks that need to be done
#    * services sometimes fail to start by init, restarting them tends to help

respawn_log=/tmp//post_boot.log



respawn_it() {
    $0 will_run > $respawn_log 2>&1
    exit 0
}



#
#  If run with no params, respawn with output going to $respawn_log
#  all to be inittab friendly
#
if [ "$1" = "" ]; then
    echo "with no param this is respawned, logging to: $respawn_log:"
    respawn_it
fi


#
#  /dev/null gets screwed up at times.
#  Recreate if it needs fixing.
#
# shellcheck disable=SC2010
if ! ls -l /dev/null | grep -q "root root 1, 3"; then
    #
    #  Depending on the nature of the /deb/null issue
    #  and since this scripts output is captured in a log file
    #  The /dev/null issue might cause the logging of the fix
    #  not to happen... Weird but I havent found away arround this
    #
    rm /dev/null > /tmp/profile.debug 2>&1
    mknod /dev/null c 1 3 >> /tmp/profile.debug 2>&1
    chmod 666 /dev/null >> /tmp/profile.debug 2>&1

    echo "Fixed /dev/null"
    #
    #  Since /dev/null was recreated respawn this (again),
    #  in order for the redirects used on this script to work
    #  all logging up this point likely didn't happen.
    #
    respawn_it
fi


# The following is needed for upstream PR #1716
if [ ! -e /dev/fd ]; then
    ln -s /proc/self/fd /dev/fd
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


# Hack for Alpine 3.14.0
OS="$(/bin/cat /etc/alpine-release)"

if [ "$OS" = '3.14.0' ]; then
    # In Alpine 3.14 services do not start up correctly.  Run script to fix 
    # that if needed
    /usr/local/bin/fix_services
fi


# /etc/init.d/networking keeps getting an extra } written at the end
# For some unknown reason.  Overwrite it when we login to hopefully
# mitigate that
#cp /root/init.d/networking /etc/init.d


#
#  Restart all services not in started state, should not be needed normally
#  but here we are, and if they are already running, nothing will happen.
#
# shellcheck disable=SC1007
current_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
"$current_dir"/do_fix_services
