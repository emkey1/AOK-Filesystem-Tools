#!/bin/sh
#
#  Part of https://github.com/jaclu/AOK-Filesystem-Tools
#
#  Copyright (c) 2023: Jacob.Lundqvist@gmail.com
#
#  License: MIT
#
#  Workarround an iOS 17 issue that the builtin hostanme provided by
#  the iSH app no longer works.
#
#  Call this from inittab in order to have hostname setup.
#  iSH-AOK can set hostname using the built in hostname cmd, so for aok
#  kernels  the custom hostname cmd is removed if found, and hostname
#  is setup to work "as normal"
#

#===============================================================
#
#   Main
#
#===============================================================

# log_file="/var/log/hostnaming.log"

#  This also updates /etc/hostname
/opt/AOK/common_AOK/usr_local_bin/hostname --update

# echo "[$(date)] ><> hostname by shortcut [$(/opt/AOK/common_AOK/usr_local_bin/hostname)] def [$(/bin/hostname)]" >>"$log_file"

if grep -qi aok /proc/ish/version 2>/dev/null; then
    rm -f /usr/local/bin/hostname
    /bin/hostname -F /etc/hostname
    # echo "[$(date)] ><> hostfile content [$(cat /etc/hostname)] assigned hostname [$(/bin/hostname)]" >>"$log_file"
fi
