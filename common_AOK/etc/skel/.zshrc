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
*) return ;; # If not running interactively, don't do anything
esac

#
#  Common settings that can be used by most shells
#
if [ -f ~/.common_rc ]; then
    . ~/.common_rc
fi

#
#  Bash style prompt
#
# PROMPT='%(?..%F{red}?%?)%F{46}%n@%m%f%b:%F{12}%~%f%b%# '

#
#  Folder and success of last cmd on left
#  user@machine time on right
#
PROMPT='%(?..%F{red}?%?)%F{12}%~%f%b%# '
RPROMPT='%F{green}%n@%m %F{240}%*%f'
