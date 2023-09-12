#!/bin/zsh
#  Fake bangpath to help editors and linters
#
#  Configure interactive zsh shells
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
#  Add colors to prompt if terminal supports it
#
if [[ $EUID -eq 0 ]]; then
    PS1='%F{%(?.red.bold.normal)}%n@%m:%F{%(?.blue.normal)}%~%f# '
else
    PS1='%F{%(?.green.bold.normal)}%n@%m:%F{%(?.blue.normal)}%~%f$ '
fi

#
#  Common settings that can be used by most shells
#
if [ -f ~/.common_rc ]; then
    . ~/.common_rc
fi
