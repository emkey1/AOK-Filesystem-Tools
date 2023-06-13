#!/usr/bin/env bash

#!/bin/sh
#
#  Part of https://github.com/emkey1/AOK-Filesystem-Tools
#
#  License: MIT
#
#  Set nav key workaround for tmux
#

tmux_mod_arrow() {
    mod="$1"
    case $mod in
    ctrl) mod="C" ;;
    shift) mod="S" ;;

    *) error_msg "arrow_mod - param must be shift/ctrl" ;;
    esac
    {
        echo "bind -n  ${mod}-Up     send-keys PageUp"
        echo "bind -n  ${mod}-Down   send-keys PageUp"
        echo "bind -n  ${mod}-Left   send-keys PageUp"
        echo "bind -n  ${mod}-Right  send-keys PageUp"
    } >"$f_tmux_nav_key_handling"
}

tmux_esc_prefix() {
    sequence="$1"
    if [ "$sequence" = " " ]; then
        echo "No special tmux Escape handling requested"
        rm -f "$f_tmux_nav_key_handling"
        exit 0
    fi

    echo "Escape prefixing will be mapped to: $sequence"
    {
        echo
        echo "# Using Esc prefix for nav keys"
        echo
        echo "set -s user-keys[200]  \"$sequence\"" # multiKeyBT

        echo "bind -n User200 switch-client -T multiKeyBT"

        echo "bind -T multiKeyBT  Down     send PageDown"
        echo "bind -T multiKeyBT  Up       send PageUp"
        echo "bind -T multiKeyBT  Left     send Home"
        echo "bind -T multiKeyBT  Right    send End"
        echo
        echo "# Double tap for actual Esc"
        echo "bind -T multiKeyBT  User200  send Escape"
    } >"$f_tmux_nav_key_handling"
}

add_to_sequence() {
    new_char="$1"
    if [ -z "$new_char" ]; then
        echo "ERROR: add_to_sequence() - no param"
    fi
    if [[ ! "$new_char" =~ [[:print:]] ]]; then
        #  Use three digit octal notation for non printables
        octal="$(printf "%o" "'$new_char'")"
        if [ $octal -lt 100 ]; then
            new_char="\\0$octal"
        else
            new_char="\\$octal"
        fi
    fi
    sequence="$sequence$new_char"
}

capture_keypress() {
    # Set terminal settings to raw mode
    stty raw -echo

    # Capture a single character
    char=$(dd bs=1 count=1 2>/dev/null)
    add_to_sequence "$char"

    # Check if more characters were generated
    IFS= read -rsn1 -t 0.1 peek_char
    while [ -n "$peek_char" ]; do
        char=$peek_char
        add_to_sequence "$char"
        IFS= read -rsn1 -t 0.1 peek_char
    done

    # Restore terminal settings
    stty sane
}

select_esc_key() {
    text="
This is a workarround to map Escape + arrows to the nav keys.
Be aware that the drawback of using this is that in order to generate Escape
inside tmux, you need to hit Esc twice.
If this outweighs the benefit of having the additional navigation keys
only you can decide.

If you want to enable this feature, hit the key you would use as Esc on your
keyboard. If you do not want to use this feature, hit space

In most cases, if you have selected 'External Keyboard - Backtic -> Escape'
This key would actually generate Esc, but this is not always the case.
For example the keyboard identified in BT settings as 'Yoozon 3.0 Keyboard'
generates (octal) \302\247 for the key, even with the backtick setting.

For such keyboards, this will also enable the intended key to generate Escape
in the first place inside tmux.
"
    echo "$text"

    capture_keypress

    # if [[ "$sequence" = " " ]]; then
    #     echo "No special tmux Escape handling requested"
    # fi

    tmux_esc_prefix "$sequence"

    # echo "tmux_esc_char=$sequence" >/etc/opt/tmux_esc_prefix
}

select_nav_key_type() {
    text="
With the iSH-AOK kernel, you can use modifiers for the arrow keys.

Select modifier:
0 - Do not use a nav-key work-arround
1 - Shift arrows
2 - Ctrl  arrows
3 - Escape prefix, then arrows, actual Escape requires Escape double tap

"
    #  3 - Alt(Meta) arrows

    echo "$text"
    read -r selection

    case "$selection" in

    0)
        echo "Do not use a nav-key work-arround"
        rm -f "$f_tmux_nav_key_handling"
        ;;

    1)
        echo "Use Shift-Arrows for nav-keys"
        tmux_mod_arrow "shift"
        ;;
    2)
        echo "Use Ctrl-Arrows for nav-keys"
        tmux_mod_arrow "ctrl"
        ;;
    #3)
    #    echo "Use Alt-Arrows for nav-keys"
    #    echo "Meta" > "$f_tmux_nav_key_handling"
    #    ;;
    #4)
    3)
        echo "Use Escape as prefix"
        select_esc_key
        ;;
    *)
        echo "*****   Invalid selection   *****"
        sleep 1
        select_nav_key_type
        ;;
    esac

}

#===============================================================
#
#   Main
#
#===============================================================

. /opt/AOK/tools/utils.sh

f_tmux_nav_key_handling="/etc/opt/tmux_nav_key_handling"

text="
Since most iOS keyboards do not have dedicated PageUp, PageDn, Home and End
keys, inside tmux this can be solved by using work-arrounds.
Outside tmux, this setting will have no effect.

This setting can be changed at any time by running /usr/local/bin/nav_keys.sh
And will take effect next time you start tmux.

If you do not use a seperate keyboard, this setting has no effect.
"

echo "$text"
#if true; then
if is_aok_kernel; then
    select_nav_key_type
else
    select_esc_key
fi

# RVV

# add bt-keyb script to .tmux.conf if /etc/opt/BT-keyboard found, run it to bind esc as prefix for PgUp/PgDn/Home/End via arrows

# install, last steps
# In case you use a BT keyboard and want to map Esc-arrows to PgUp/PgDn/Home/End inside tmux, select your keyboard from the list below. If you select none your keyb will still work, but no extra binding will happen inside tmux

# - Explain why and ask if any but keyb should be selected, if yes store in /etc/opt/BT-keyboard
