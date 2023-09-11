#!/bin/zsh
#   Fake bangpath to help editors and linters
#
#  Part of https://github.com/jaclu/AOK-Filesystem-Tools
#
#  License: MIT
#
#  Copyright (c) 2023: Jacob.Lundqvist@gmail.com
#
#  Configure interactive zsh shells
#

#
#  Add colors to prompt if terminal supports it
#
if [[ $EUID -eq 0 ]]; then
    PS1='%F{%(?.red.bold.normal)}%n@%m:%F{%(?.blue.normal)}%~%f# '
else
    PS1='%F{%(?.green.bold.normal)}%n@%m:%F{%(?.blue.normal)}$ '
fi

#
#  Common settings that can be used by most shells
#
if [ -f ~/.common_rc ]; then
    . ~/.common_rc
fi
