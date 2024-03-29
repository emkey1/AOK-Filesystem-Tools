#!/bin/sh
#
#  Part of https://github.com/jaclu/AOK-Filesystem-Tools
#
#  Copyright (c) 2023: Jacob.Lundqvist@gmail.com
#
#  License: MIT
#
#  Ensure that hostname is in /etc/hosts, if not add it to loopback
#  some stuff looks up 'hostname' and fail or display warnings if
#  it cant be resolved, its not a CPU drain, and it never hurts...
#

host_file="/etc/hosts"
host_name="$(hostname | tr '[:upper:]' '[:lower:]')"

#
#  Since this will be run from inittab before /etc/init.d/hostname
#  has started, you most likely will end up with both variants of the
#  hostname in /etc/hosts when using AOK_HOSTNAME_SUFFIX:
#    127.0.0.1   myipad
#    127.0.0.1   myipad-aok
#  That shouldnt be a problem, since the typical reason for enabling
#  AOK_HOSTNAME_SUFFIX in the first place is if you run both iSH &
#  iSH-AOK on the same device.
#
if ! grep -q "127.0.0.1[[:space:]]$host_name$" "$host_file"; then
    echo "[$(date)] adding hostname: $host_name to $host_file" >>/var/log/syslog
    printf '127.0.0.1\t%s\n' "$host_name" >>"$host_file"
fi
