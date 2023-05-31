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
    esc_shar_oct="$1"

    if [ -z "$esc_shar_oct" ]; then
        echo "ERROR: define_tmux_esc() - no param"
        exit 1
    fi

    tmux set -s user-keys[200] "$esc_shar_oct" # multiKeyBT

    tmux bind -T multiKeyBT User200 send Escape
    tmux bind -T multiKeyBT Down send PageDown
    tmux bind -T multiKeyBT Up send PageUp
    tmux bind -T multiKeyBT Left send Home
    tmux bind -T multiKeyBT Right send End

    tmux bind -n User200 switch-client -T multiKeyBT
}

ios_bt_keyboard=/etc/opt/BT_keyb

if [ ! -f "$ios_bt_keyboard" ]; then
    #  No BT keyb defined for Escape handling
    exit 0
fi

if [ -z "$TMUX_BIN" ]; then
    #  For now this can only be used inside tmux
    exit 0
fi

. "$ios_bt_keyboard"

#  Only run if esc is defined
[ -n "$esc_char_oct" ] && define_tmux_esc "$esc_char_oct"
