#!/bin/sh
#
#  Copyright (c) 2022: Jacob.Lundqvist@gmail.com
#  License: MIT
#
#   Version: 1.1.1  2022-05-20
#
#  Intended usage is for cronless systems, needing to do some sanity checks
#  after booting. Trigger this in /etc/inittab by adding a line:
#
#  ::wait:/usr/local/bin/post_boot.sh
#
#  Before starting /sbin/openrc or similar
#


#
#  If run with no params, spawn another instance in the background and exit
#  in order to be inittab friendly
#
if [ "$1" = "" ]; then
    $0 will_run &
    exit 0
fi

#
# Give the system time to complete it's startup
#
sleep 10


#
#  Do all sanity checks needed...
#


#
#  Restart all services nnot in started state
#
rc-status |grep -v -e started -e Runlevel:  | awk '{ print $1 }' | xargs -I % sudo /etc/init.d/% restart >> /tmp/post_boot.log
