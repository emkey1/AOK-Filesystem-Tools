#!/bin/sh
#
#  Part of https://github.com/jaclu/AOK-Filesystem-Tools
#
#  Copyright (c) 2023: Jacob.Lundqvist@gmail.com
#
#  License: MIT
#
#  Lists all apks that provides prog, and it is much faster than
#  the apk tool
#

error_msg() {
    msg="$1"
    [ -z "$msg" ] && error_msg "error_msg() called with no param"
    echo "ERROR: $msg"
    exit 1
}

show_help() {
    echo "Usage: $prog_name prog

This lists all apks, that provides the program: prog"
    exit 0
}

#===============================================================
#
#   Main
#
#===============================================================

prog_name=$(basename "$0")

case "$1" in

    "-h" | "--help") show_help ;;

    *) prog="$1" ;;

esac

#  Some param checks
[ -z "$prog" ] && error_msg "no param, try -h"
echo "$prog" | grep -q '/' &&  error_msg "Cant contain / chars"

#
#  Creating cmd step by step, so that each sub-task can be explained
#

#  list all the tar files containing info about apks
cmd="ls /var/cache/apk/*.tar.gz"

#  Process each file, unpacking it and examining content
cmd="$cmd | xargs -I {} tar -zxf {} -O"
    
#
#  For each match show the preceeding lines in order to find package
#  name, records seems to normally be 14 lines, so grab a bit more to
#  be somewhat future proof
#
cmd="$cmd | grep -a -B 16 cmd\:${prog}="

#
#  reverse this output, and search for the line starting with P:
#  this should be the corresponding package name
#  This reversal will slightly improve the result in case the lines
#  extracted above ends up spanning more than one package. Bad but
#  at least the relevant package is listed first.
#
cmd="$cmd | sort -r | grep '^P:'"

#  filter out the P: prefix
cmd="$cmd | cut -d: -f2"

eval "$cmd"
