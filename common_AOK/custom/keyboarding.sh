#!/bin/sh

define_tmux_esc() {
    #
    #  Use this char (in oct) as escape
    #  mappings
    #   Esc-Up     PageUp
    #   Esc-Down   PageDown
    #   Esc-Left   Home
    #   Esc-Right  End
    #   Esc-Esc    Esc
    #
    esc_sequence="$1"

    if [ -z "$esc_sequence" ]; then
        echo "ERROR: define_tmux_esc() - no param"
        exit 1
    fi

    echo "tmux Using [$esc_sequence]"

    $TMUX_BIN set -s user-keys[200] "$esc_sequence" # multiKeyBT

    $TMUX_BIN bind -T multiKeyBT User200 send Escape
    $TMUX_BIN bind -T multiKeyBT Down send PageDown
    $TMUX_BIN bind -T multiKeyBT Up send PageUp
    $TMUX_BIN bind -T multiKeyBT Left send Home
    $TMUX_BIN bind -T multiKeyBT Right send End

    $TMUX_BIN bind -n User200 switch-client -T multiKeyBT
}

#===============================================================
#
#   Main
#
#===============================================================

# Set env variable across ssh sessions so that remote tmux sessions
# honor the same nav key handling
# Would it need unbind in case of change nav handling?
# no tmux should be restarted
#
# tmux source a conf file dedicated to handle this, sample lines
#
# bind -N "S-Up = PageUp"     -n  S-Up     send-keys PageUp
# bind -N "C-Up = PageUp"     -n  S-Up     send-keys PageUp
# bind -N "M-Up = PageUp"     -n  S-Up     send-keys PageUp
#
# set -s user-keys[200]  "{key_oct}"  # multiKeyNav
#
# bind -n User200 switch-client -T multiKeyNav
# bind -T multiKeyNav  User200  send Escape
# bind -T multiKeyNav  Down     send PageDown
# bind -T multiKeyNav  Up       send PageUp
# bind -T multiKeyNav  Left     send Home
# bind -T multiKeyNav  Right    send End

tmux_nav_key_handling="/etc/opt/tmux_nav_key_handling"

if [ ! -f "$tmux_nav_key_handling" ]; then
    #  No BT keyb defined for Escape handling
    exit 0
fi

if [ -z "$TMUX" ]; then
    #  For now this can only be used inside tmux
    exit 0
fi

nav_key_handling="$(cat $tmux_nav_key_handling)"

#  Only run if esc is defined
[ -n "$nav_key_handling" ] && define_tmux_esc "$nav_key_handling"
