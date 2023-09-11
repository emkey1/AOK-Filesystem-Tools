#!/bin/bash
#   Fake bangpath to help editors and linters
#
#  Part of https://github.com/jaclu/AOK-Filesystem-Tools
#
#  License: MIT
#
#  Copyright (c) 2023: Jacob.Lundqvist@gmail.com
#
# ~/.bash_profile: executed by bash(1) for login shells.
#

#
#  If found, run the common init script used by non-login shells,
#  in order to keep the setup in one place
#
if [[ -f ~/.bashrc ]]; then
    # shellcheck source=/opt/AOK/common_AOK/etc/skel/.bashrc
    . ~/.bashrc
fi
