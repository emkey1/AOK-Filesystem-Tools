#!/usr/bin/env bash
#
#  Part of https://github.com/jaclu/ish-config
#
#  Copyright (c) 2022-2024: Jacob.Lundqvist@gmail.com
#
#  License: MIT
#
#  Extraction of zone time offsets derived from
#  https://gist.github.com/eduardoaugustojulio/fa83cf85efa39919d6a70ca679e91f28
#

do_clear() {
    #
    #  dialog ueses an option too clear screen after an item is displayed
    #  this is only needed for whiptail
    #
    [[ "$dialog_app" = "whiptail" ]] && clear
}

check_dependencies() {
    #
    #  Ensure needed stuff is installed
    #
    apks=()

    dlg_app="$(echo "$dialog_app" | cut -d ' ' -f 1)"

    if [[ -z "$(command -v "$dlg_app")" ]]; then
        dependency="$dlg_app"

        if [[ $dependency = "whiptail" ]] && [[ -f /etc/alpine-release ]]; then
            #  In Alpine, whiptail is part of newt, correct the dependency
            dependency="newt"
        fi
        apks+=("$dependency")
    fi

    [[ ! -d /usr/share/zoneinfo ]] && apks+=(tzdata)

    if ((${#apks[@]})); then
        printf 'Installing %s dependencies: ' "$0"
        printf '%s ' "${apks[@]}"
        printf '\n\n'

        if [[ -f /etc/debian_version ]]; then
            #  Prevent debians built in dialog,
            bash -c "DEBIAN_FRONTEND=noninteractive apt install -y ${apks[*]}"
        else
            #  shellcheck disable=SC2068
            apk add ${apks[@]}
        fi
    fi
}

get_tz_regions_lst() {
    regions=$(find /usr/share/zoneinfo/. -maxdepth 1 -type d |
        cut -d "/" -f6 | sed '/^$/d' | awk '{print $0 ""}' | sort)
}

get_tz_options_lst() {
    options=$(cd /usr/share/zoneinfo/"$1" && find . | sed 's|^\./||' |
        sed 's/^\.//' | sed '/^$/d' | sort)
}

main() {
    tZone="" # Needs to be cleared in case Back (to main) was selected
    #
    #  Select Region
    #
    get_tz_regions_lst

    region_items=()
    while read -r name; do
        #  skip invalids
        [[ "$name" = "right" ]] && continue

        region_items+=("$name" "")
    done <<<"$regions"

    # tested size 20 0 10
    region=$($dialog_app \
        --title "Timezones - region" \
        --backtitle "Region details takes a few seconds to prepare..." \
        --ok-button "Next" \
        --menu "Select a region, or Etc for direct TZ:" 0 0 0 \
        "${region_items[@]}" \
        3>&2 2>&1 1>&3-)

    if [[ -z "$region" ]]; then
        return
    fi
    #
    #  Select a zone within a region
    #
    get_tz_options_lst "$region"

    option_items=()
    while read -r name; do
        offset=$(TZ="$region/$name" date +%z | sed "s/00$/:00/g")
        option_items+=("$name" " ($offset)")
    done <<<"$options"

    menu_title="Select your timezone in\\nregion: ${region}"
    test "$region" = 'Etc' && menu_title="$menu_title\\n\\nPlease note POSIX and ISO use oposite signs\\nfor numerical time-zone references!\\nFocus on the right column in this table"
    tz=$($dialog_app \
        --title "Timezones - location" \
        --ok-button "Select" \
        --cancel-button "Back" \
        --menu "$menu_title" 0 0 0 \
        "${option_items[@]}" \
        3>&2 2>&1 1>&3-)

    if [[ -z "$tz" ]]; then
        #
        #  Back was selected, recurse one level. If something eventually is
        #  selected, the outermost layer of this will use it once exiting.
        #
        main
        # tZone will already be set, so just return now
        return
    fi

    selected_tz="$region/$tz"
    if [[ "$selected_tz" = "/" ]]; then
        return
    fi

    if ! $dialog_app --yesno "Setting Time Zone to:\\n\\n    $selected_tz\\n" 0 0; then
        #  recurse and try again
        main
    else
        tZone="$region/$tz"
    fi
}

#===============================================================
#
#   Main
#
#===============================================================

#
#  Dialog is the original and most feature complete implementation.
#  Whiptail is a slightly simplified fork made by RedHat, and uses newt
#  instead of ncurses for screen handling, so might have a more
#  recognizable styling. For this app, either is fine.
#

dialog_app="whiptail"
#  dialog_app="dialog" # --erase-on-exit"

TMPDIR="${TMPDIR:-/tmp}"

# execute again as root
if [[ "$(whoami)" != "root" ]]; then
    # using $0 instead of full path makes location not hardcoded
    if ! sudo "$0" "$@"; then
        echo
        echo "ERROR: Failed to sudo $0"
        echo
    fi
    exit 0
fi

check_dependencies

main

if test -n "$tZone"; then
    #
    #  Use the selected time-zone
    #
    echo "Using time zone: $tZone"
    ln -sf "/usr/share/zoneinfo/$tZone" /etc/localtime
fi

# do_clear
