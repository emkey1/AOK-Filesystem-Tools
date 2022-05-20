#!/bin/sh
#
#  Version: 1.1.2  2022-05-20
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


#
#  If run with no params, spawn another instance in the background and exit
#  in order to be inittab friendly
#
if [ "$1" = "" ]; then
    $0 will_run >> /tmp/post_boot.log 2>> /tmp/post_boot.err &
    exit 0
fi

#
# Give the system time to complete it's startup
#
sleep 10


#
#  Do all sanity checks needed...
#

# The following is needed for upstream PR #1716
if [ ! -e /dev/fd ]; then
   ln -s /proc/self/fd /dev/fd
fi


if [[ -e /etc/FIRSTBOOT ]]; then
   # /dev/null gets screwed up at times.  Recreate just in case
   # the first time we boot
   rm /dev/null > /tmp/profile.debug 2>&1
   mknod /dev/null c 1 3 >> /tmp/profile.debug 2>&1
   chmod 666 /dev/null >> /tmp/profile.debug 2>&1

   # Start a couple of services
   rc-update add dcron
   rc-update add runbg

   rm /etc/FIRSTBOOT # Only do this stuff once, so remove the file now
fi

# Hack for Alpine 3.14.0
OS=`/bin/cat /etc/alpine-release`

if [ $OS = '3.14.0' ]; then
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
rc-status |grep -v -e started -e Runlevel:  | awk '{ print $1 }' | xargs -I % /etc/init.d/% restart
