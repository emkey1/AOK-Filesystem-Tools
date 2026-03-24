#!/bin/zsh
#   Fake bangpath to help editors and linters
#
#  Part of https://github.com/jaclu/AOK-Filesystem-Tools
#
#  License: MIT
#
#  Copyright (c) 2023,2024: Jacob.Lundqvist@gmail.com
#
#  Configure interactive zsh shells
#

#
#  Non-interactive shells wont read this by themselves. This ensures
#  that if they get here via idirect sourcing, they abort.
#
echo "$-" | grep -qv 'i' && return # non-interactive

#
#  Common settings that can be used by most shells
#
if [ -f ~/.common_rc ]; then
    . ~/.common_rc
fi

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

#===============================================================
#
#   Main
#
#===============================================================

zsh_history_conf

prompt_colors

_user_host_name="%F{$PCOL_USERNAME}%n%F{$PCOL_GREY}@%F{$PCOL_HOSTNAME}$_hn"

#
#  CWD and success of last cmd on left
#  user@machine [sysload battery_lvl] time on right
#
PROMPT="%(?..%F{red}?%?)%F{$PCOL_CWD}%~%f%b%# "

#
#  set to false if you don't want a dynamic rprompt displaying
#  sysload and (on ish-aok) battery lvl
#
if true; then
    update_prompt_content() {
        if grep -qi aok /proc/ish/version 2>/dev/null; then
            _s="$_user_host_name $(get_sysload_lvl)$(get_battery_info zsh)"
            _s="$_s %F{$PCOL_GREY}%*%f"
            RPROMPT="$_s"
            unset _s
        else
            if [ -f /etc/alpine-release ]; then
		RPROMPT="$_user_host_name $(get_sysload_lvl) %F{$PCOL_GREY}%*%f"
            else
                # iSH Debian doesn't provide sysload
		RPROMPT="$_user_host_name %F{$PCOL_GREY}%*%f"
            fi
        fi
	return 0
    }

    precmd() {
        update_prompt_content
    }

    # initial prompt update
    update_prompt_content
else
    RPROMPT="$_user_host_name %F{$PCOL_GREY}%*%f"
fi
