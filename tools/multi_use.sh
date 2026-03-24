#!/bin/sh
#
#  Part of https://github.com/jaclu/AOK-Filesystem-Tools
#
#  License: MIT
#
#  Copyright (c) 2023: Jacob.Lundqvist@gmail.com
#
#  Tools used both during deploy and upgrades
#

replace_std_bin() {
    f_bin="$1"
    f_bin_replacement="$2"
    upgrade="$3"

    [ -z "$f_bin" ] && error_msg "replace_std_bin() - missing 1st param"
    [ -z "$f_bin_replacement" ] && {
        error_msg "replace_std_bin($f_bin,) - missing 2nd param"
    }
    case "$upgrade" in
    "" | "upgrade") ;;
    *)
        _s="replace_std_bin() - Invalid upgrade option: [$upgrade]"
        error_msg "$_s"
        ;;
    esac

    # Check if it is done already
    [ "$(realpath "$f_bin")" = "$(realpath "$f_bin_replacement")" ] && {
        return
    }

    msg_3 "Softlinking $f_bin_replacement -> $f_bin"

    f_bin_org="$(dirname "$f_bin")/ORG.$(basename "$f_bin")"
    if [ ! -f "$f_bin_org" ]; then
        if [ -f "$f_bin" ]; then
            msg_4 "Renaming original $f_bin -> $f_bin_org"
            mv "$f_bin" "$f_bin_org"
        else
            msg_4 "Original $f_bin - not found"
        fi
    fi

    [ -f "$f_bin" ] && {
        [ "$upgrade" != "upgrade" ] && {
            _s="$f_bin_replacement already pressent, removing $f_bin"
            error_msg "$_s" -1
        }
        rm -f "$f_bin"
    }
    ln -sf "$f_bin_replacement" "$f_bin"
}

# shellcheck disable=SC2120
replacing_std_bins_with_aok_versions() {
    #
    #  Replacing some stadard bins with AOK version
    #
    upgrade="$1"

    msg_2 "Replacing std bins with AOK versions"

    # Hostname can be in different places depending on Distro
    org_hostname=/usr/bin/hostname
    [ ! -f "$org_hostname" ] && org_hostname=/bin/hostname

    [ "$1" != "upgrade" ] && {
        #
        # on 1st boot original hostname can be used to pick up name
        # of host, mostly useful when chrooted, since on iOS devices
        # it will just report localhost
        #

        # Used by utils:set_hostname()
        $org_hostname -s >"$f_hostname_initial"

        msg_4 "Using org hostname to store what it reports"
        msg_4 " [$(cat "$f_hostname_initial")] in: $f_hostname_initial"
    }

    replace_std_bin "$org_hostname" /usr/local/bin/hostname "$upgrade"
    replace_std_bin /usr/bin/wall /usr/local/bin/wall "$upgrade"
    replace_std_bin /sbin/shutdown /usr/local/sbin/shutdown "$upgrade"
    replace_std_bin /sbin/halt /usr/local/sbin/halt "$upgrade"
    replace_std_bin /sbin/poweroff /usr/local/sbin/halt "$upgrade"

    if this_is_aok_kernel; then
        # ish-aok does not need the replacement uptime
        org_uptime=/usr/bin/ORG.uptime
        def_uptime=/usr/bin/uptime
        [ -x "$org_uptime" ] && {
            msg_4 "reactivate org uptime"
            rm -f "$def_uptime"
            mv "$org_uptime" "$def_uptime"
        }
        [ "$(realpath "$def_uptime")" = "$def_uptime" ] && {
            msg_4 "remove replacement uptime"
            rm -f /usr/local/bin/uptime
        }
    elif [ -f /etc/debian_version ]; then
        replace_std_bin /usr/bin/uptime /usr/local/bin/uptime "$upgrade"
    fi
}

#===============================================================
#
#   Main
#
#===============================================================

# shellcheck source=/opt/AOK/tools/utils.sh
[ -z "$d_aok_etc" ] && . /opt/AOK/tools/utils.sh

# usage for updates:
# replacing_std_bins_with_aok_versions upgrade
