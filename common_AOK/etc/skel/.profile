#!/bin/sh
#   Fake bangpath to help editors and linters
#
#  Part of https://github.com/jaclu/AOK-Filesystem-Tools
#
#  License: MIT
#
#  Copyright (c) 2023,2024: Jacob.Lundqvist@gmail.com
#
# ~/.profile: executed by the command interpreter for login shells.
# This file is not read by bash(1), if ~/.bash_profile or ~/.bash_login
# exists.
# see /usr/share/doc/bash/examples/startup-files for examples.
# the files are located in the bash-doc package.
#
#
#  Non-interactive shells wont read this by themselves. This ensures
#  that if they get here via idirect sourcing, they abort.
#
echo "$-" | grep -qv 'i' && return # non-interactive

use_ash_env() {
    #
    #  If ENV is defined  ash & dash will use it
    #  on Alpine ash is usually softlinked to busybox
    #
    [ -f "$HOME/.ash_init" ] && export ENV="$HOME/.ash_init"
}

# umask 022

#
#  A bash login shell reads the first found of:
#  ~/.bash_profile ~/.bash_login ~/.profile
#  Since ~/.bash_profile is provided in AOK_FS
#  There will normally not be a need to handle bash here.
#
if [ -f /proc/$$/exe ]; then
    CURRENT_SHELL="$(basename "$(readlink /proc/$$/exe)")" || {
	CURRENT_SHELL="" # unknown
    }
    case "$CURRENT_SHELL" in
        ash | busybox | dash)
	    use_ash_env
            ;;
        *) ;;
    esac
else
    # /proc/$$/exe not found, fall back to $0 check
    case "$0" in
        "-ash" | "ash" | "/bin/ash" | "-dash" | "dash")
            #
            #  If ENV is defined  ash & dash will use it
            #
	    use_ash_env
            ;;
        *) ;;
    esac
fi
