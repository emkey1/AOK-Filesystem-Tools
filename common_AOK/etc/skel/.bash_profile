#!/bin/bash
#  Fake bangpath to help editors and linters
#
# ~/.bash_profile: executed by bash(1) for login shells.
#


#
#  Non-interactive shells wont read this by themselves. This ensures
#  that if they get here via idirect sourcing, they abort.
#
case $- in
    *i*) ;;
      *) return;; # If not running interactively, don't do anything
esac


#
#  If found, run the common init script used by non-login shells,
#  in order to keep the setup in one place
#
if [[ -f ~/.bashrc ]]; then
    # shellcheck source=/opt/AOK/common_AOK/etc/skel/.bashrc
    . ~/.bashrc
fi
