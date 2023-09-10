# ~/.profile: executed by the command interpreter for login shells.
# This file is not read by bash(1), if ~/.bash_profile or ~/.bash_login
# exists.
# see /usr/share/doc/bash/examples/startup-files for examples.
# the files are located in the bash-doc package.

# the default umask is set in /etc/profile; for setting the umask
# for ssh logins, install and configure the libpam-umask package.
#umask 022

#  If not running interactively, don't go further
case $- in

    *i*) ;;

    *) return  ;;

esac

case "$0" in

    "-ash" | "ash" | "-dash" | "dash" )
        ENV=$HOME/.ash_init; export ENV
        # echo ">> ENV is set to: $ENV"
        ;;

    "-bash" | "bash" )
        if [ -n "$PS1" -a -n "$BASH_VERSION" ]; then
	    . "$HOME/.bashrc"
        fi
        ;;

    *) ;;

esac


# set PATH so it includes user's bin if it exists
if [ -d "$HOME/bin" ] ; then
    PATH="$HOME/bin:$PATH"
fi

# set PATH so it includes user's local bin if it exists
if [ -d "$HOME/.local/bin" ] ; then
    PATH="$HOME/.local/bin:$PATH"
fi
