#!/bin/bash
#   Fake bangpath to help editors and linters
#
#  Part of https://github.com/jaclu/AOK-Filesystem-Tools
#
#  License: MIT
#
#  Copyright (c) 2023,2024: Jacob.Lundqvist@gmail.com
#
#  executed by bash(1) for non-login shells.
#

#
#  Non-interactive shells wont read this by themselves. This ensures
#  that if they get here via idirect sourcing, they abort.
#
case $- in
*i*) ;;
*) return ;; # If not running interactively, exit now!
esac

#
#  Common settings that can be used by most shells, should be done early
#  So shell specific init can override anything in here
#

#  shellcheck source=/opt/AOK/common_AOK/etc/skel/.common_rc
if [[ -f ~/.common_rc ]]; then
    # shellcheck source=/dev/null
    . ~/.common_rc
fi

# don't put duplicate lines or lines starting with space in the history.
# See bash(1) for more options
HISTCONTROL=ignoreboth

# append to the history file, don't overwrite it
shopt -s histappend

# for setting history length see HISTSIZE and HISTFILESIZE in bash(1)
HISTSIZE=1000
HISTFILESIZE=2000

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

# If set, the pattern "**" used in a pathname expansion context will
# match all files and zero or more directories and subdirectories.
#shopt -s globstar

#
#  enable programmable completion features
#
if ! shopt -oq posix; then
    if [[ -f /usr/share/bash-completion/bash_completion ]]; then
        # shellcheck source=/dev/null
        . /usr/share/bash-completion/bash_completion
    elif [[ -f /etc/bash_completion ]]; then
        # shellcheck source=/dev/null
        . /etc/bash_completion
    fi
fi

#
#  Use either one, dynamic will display sysload 5 and on ish-AOK batt-lvl
#
use_dynamic_bash_prompt
# use_static_bash_prompt
