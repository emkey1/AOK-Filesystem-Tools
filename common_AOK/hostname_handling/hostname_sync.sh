#!/bin/sh
#
#  Part of https://github.com/jaclu/AOK-Filesystem-Tools
#
#  Copyright (c) 2023: Jacob.Lundqvist@gmail.com
#
#  License: MIT
#
#  workaround an iOS 17 issue that the builtin hostanme provided by
#  the iSH app no longer works.
#
#  For more details see
#  https://github.com/jaclu/AOK-Filesystem-Tools/blob/main/Docs/hostname-shortcut.md
#
#  Call this from inittab in order to have hostname setup.
#  iSH-AOK can set hostname using the built in hostname cmd, so for aok
#  kernels  the custom hostname cmd is removed if found, and hostname
#  is setup to work "as normal"
#
#  For regular iSH you need to have /usr/local/bin early in path
#  in order for the custom hostname bin to be used.
#  in bash/ash prompts you can not display hostname with the default \h
#  since it is hardcoded to use /bin/hostname and thus will display localhost
#  instead use $(/usr/local/bin/hostname -s) to make sure actual hostname
#  is used
#

#===============================================================
#
#   Main
#
#===============================================================

hostname_alt=/usr/local/bin/hostname

#  Only continue if alt hostname is available
[ ! -x "$hostname_alt" ] && exit 0

# skip extra displayal of hostname, but dont filter out errors
"$hostname_alt" --update >/dev/null
if grep -qi aok /proc/ish/version 2>/dev/null; then
    #
    #  Set hostname the normal way, and from now on it can be used
    #  without special considerations
    #
    /bin/hostname -F /etc/hostname
fi
