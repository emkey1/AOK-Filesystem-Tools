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

zsh_history_conf() {
    HISTSIZE=1000000
    # shellcheck disable=SC2034
    SAVEHIST=1000000
    HISTFILE=${_SE_ZSH_HISTORY_LOCATION:=${ZDOTDIR:=$HOME}}/.zsh_history
    HISTTIMEFORMAT="[%F %T] "

    # ignore case when expanding PATH params
    setopt NO_CASE_GLOB
    # With AUTO_CD enabled in zsh, the shell will automatically change directory
    # if you forget to prefix with cd
    setopt AUTO_CD

    # Corrects misspelled path and commands
    # setopt CORRECT  # this just seems annoying, "thefuck" does a better job

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

zsh_history_conf

#
#  Folder and success of last cmd on left
#  user@machine time on right
#
PROMPT='%(?..%F{red}?%?)%F{12}%~%f%b%# '

#  Inside tmux user and time is displayed on status line
[ -z "$TMUX_BIN" ] && RPROMPT="%F{green}%n@$_hn %F{240}%*%f"
