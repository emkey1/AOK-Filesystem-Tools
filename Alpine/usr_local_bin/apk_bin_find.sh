#!/usr/bin/env bash
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
    [[ -z "$msg" ]] && error_msg "error_msg() called with no param"
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

    *) cmd="$1" ;;

esac

#  Some param checks
[[ -z "$cmd" ]] && error_msg "no param, try -h"
echo "$cmd" | grep -q '/' &&  error_msg "Cant contain / chars"

search_for_it=(
    #  list all the tar files containing info about apks
     "ls /var/cache/apk/*.tar.gz"

    #  Process each file, unpacking it and examining content
    ' | xargs -I {} tar -zxf {} -O'
    
    #  For each match show the preceeding lines in order to find package
    #  name, records seems to normally be 14 lines, so grab a bit more to
    #  be somewhat future proof
    " | grep -a -B 16 cmd\:${cmd}="
    
    #  reverse this output, and search for the line starting with P:
    #  this should be the corresponding package name
    ' | sort -r | grep "^P:"' # | echo ghepp'  # | head -n 1
    
    #  filter out the P: prefix
    ' | cut -d: -f2'
)

#  shellcheck disable=SC2294
eval "${search_for_it[@]}"
