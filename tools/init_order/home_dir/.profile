#  If not running interactively, don't go further
case $- in

*i*) ;;

*) return ;;

esac

echo "--- ~/.profile [$$] [$0] [$1]"

case "$0" in

"-ash" | "ash" | "/bin/ash" | "-dash" | "dash")
    echo "    setting ENV & SHINIT"
    #
    #  ENV is the default non login init script for ash
    #  I have seen some mentions about SHINT sometimes
    #  being used, but never encountered it.
    #  This sets both
    #
    ENV="$HOME/.env_init"
    export ENV
    SHINIT="$HOME/.shinit"
    export SHINIT
    ;;

"-bash" | "bash" | "/bin/bash")
    if [ -n "$PS1" -a -n "$BASH_VERSION" ]; then
        . "$HOME/.bashrc"
    fi
    ;;

*)
    echo
    echo "***  ~/.profile did not recognize params!  ***"
    echo
    ;;

esac
