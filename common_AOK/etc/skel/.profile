#!/bin/sh
# Fake bangpath to help editors and linters

# ~/.profile: executed by the command interpreter for login shells.
# This file is not read by bash(1), if ~/.bash_profile or ~/.bash_login
# exists.
# see /usr/share/doc/bash/examples/startup-files for examples.
# the files are located in the bash-doc package.

#
#  Non-interactive shells wont read this by themselves. This ensures
#  that if they get here via idirect sourcing, they abort.
#
case $- in
*i*) ;;
*) return ;; # If not running interactively, don't do anything
esac

# the default umask is set in /etc/profile; for setting the umask
# for ssh logins, install and configure the libpam-umask package.
#umask 022

case "$0" in

"-ash" | "ash" | "/bin/ash" | "-dash" | "dash")
    #
    #  If ENV is defined  ash & dash will use it
    #
    [ -f "$HOME/.ash_init" ] && export ENV="$HOME/.ash_init"
    ;;
#
#  A bash login shell reads the first found of:
#  ~/.bash_profile ~/.bash_login ~/.profile
#  Since ~/.bash_profile is provided in AOK_FS
#  There will normally not be a need to handle bash here.
#

*) ;;

esac
