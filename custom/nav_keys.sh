#!/usr/bin/env bash

#
#  Select BT keyb if so desired
#

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

# Function to capture keypress
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

select_keyboard() {
    text="
Since most iOS keyboards do not have dedicated PageUp, PageDn, Home and End
keys, this is a workarround to map Escape + arrows to those keys.
Currently this selection is only active inside tmux.
Be aware that the drawback of using this is that in order to generate Escape
inside tmux, you need to hit Esc twice.
If this outweighs the benefit of having the additional navigation keys
only you can decide.

In most cases, if you have selected 'External Keyboard - Backtic -> Escape'
This key would actually generate Esc, but this is not always the case,
for example the keyboard 'Yoozon 3.0 Keyboard' generates (octal) \302\247
for the key, even with this setting.

If you want to enable this feature, hit the key you would use as Esc on your
keyboard. If you do not want to use this feature, hit space

"
    echo
    echo "$text"

    capture_keypress

    if [[ "$sequence" = " " ]]; then
        echo "No special tmux Escape handling requested"
	rm -f "$tmux_esc_indicator"
        exit 0
    fi

    echo "Escape prefixing will be mapped to: $sequence"
    echo "$sequence" > "$tmux_esc_indicator"
    # echo "tmux_esc_char=$sequence" >/etc/opt/tmux_esc_prefix
}

#===============================================================
#
#   Main
#
#===============================================================

tmux_esc_indicator="/etc/opt/tmux_esc_prefix"
# RVV

# add bt-keyb script to .tmux.conf if /etc/opt/BT-keyboard found, run it to bind esc as prefix for PgUp/PgDn/Home/End via arrows

# install, last steps
# In case you use a BT keyboard and want to map Esc-arrows to PgUp/PgDn/Home/End inside tmux, select your keyboard from the list below. If you select none your keyb will still work, but no extra binding will happen inside tmux

# - Explain why and ask if any but keyb should be selected, if yes store in /etc/opt/BT-keyboard
select_keyboard
