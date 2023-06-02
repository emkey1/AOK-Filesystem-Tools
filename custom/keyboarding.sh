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

tmux_esc_indicator="/etc/opt/tmux_esc_prefix"

ios_keyboard=/etc/opt/tmux_esc_prefix

if [ ! -f "$tmux_esc_indicator" ]; then
    #  No BT keyb defined for Escape handling
    exit 0
fi

if [ -z "$TMUX_BIN" ]; then
    #  For now this can only be used inside tmux
    exit 0
fi

tmux_esc_char="$(cat $tmux_esc_indicator)"

#  Only run if esc is defined
[ -n "$tmux_esc_char" ] && define_tmux_esc "$tmux_esc_char"
