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

zsh_history_config() {
    #
    # Configure how history should be used
    #
    HISTSIZE=1000000
    # shellcheck disable=SC2034
    SAVEHIST=1000000
    HISTFILE=${ZDOTDIR:=$HOME}/.zsh_history
    HISTTIMEFORMAT="[%F %T] "

    #
    #  History related
    #
    # Append to history, instead of replacing it.
    setopt APPEND_HISTORY
    # Save as : start time:elapsed seconds;command
    setopt EXTENDED_HISTORY
    # Do not store duplication's
    setopt HIST_IGNORE_ALL_DUPS
    # Do not add command line to history when the first character
    # on the line is a space, or when one of the expanded
    # aliases contains a leading space
    setopt HIST_IGNORE_SPACE
    # Filter out superfluous blanks
    setopt HIST_REDUCE_BLANKS
    # Waits until completion to save command to history. Without this, history
    # is saved as command starts, making elapsed time from EXTENDED_HISTORY
    # always being 0
    # Has no effect if SHARE_HISTORY is set
    setopt INC_APPEND_HISTORY_TIME
}

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

zsh_history_config

unset -f zsh_history_config
