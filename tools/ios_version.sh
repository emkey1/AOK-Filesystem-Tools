#!/bin/sh
# This is sourced. Fake bang-path to help editors and linters
#
#  Part of https://github.com/jaclu/AOK-Filesystem-Tools
#
#  License: MIT
#
#  Copyright (c) 2023: Jacob.Lundqvist@gmail.com
#
#  Version checks
#

#---------------------------------------------------------------
#
#   UIDevice  handling
#
#  Sample content
# cat /proc/ish/UIDevice
# Model: iPad
# OS Name: iPadOS
# OS Version: 16.6
#
#---------------------------------------------------------------

create_fake_dev_details() {
    msg_2 "Creating fake /proc/ish/UIDevice"

    #  shellcheck disable=SC2154
    d_base="$d_build_root"/proc/ish/.defaults
    if [ -f "$d_base/CarCapabilities" ]; then
        _dev_type="iPhone"
    else
        _dev_type="iPad"
    fi
    if [ -f "$d_base/WebKitShowLinkPreviews" ] ||
        [ -f "$d_base/WebKitShowLinkPreviews" ]; then
        _ios_version="17.0"
    else
        _ios_version="16.0"
    fi

    msg_3 "updating [$f_UIDevice]"
    echo "Model: $_dev_type" >"$f_UIDevice"
    echo "OS Version: $_ios_version" >>"$f_UIDevice"

    unset _dev_type
    unset _ios_version
}

host_type() {
    # msg_2 "host_os(()"
    if [ ! -f "$f_UIDevice" ]; then
        echo "Unknown"
    elif grep -qi ipad "$f_UIDevice"; then
        echo "iPad"
    else
        echo "iPhone"
    fi
    # msg_3 "host_os(() - done"
}

host_ios_version() {
    #
    #  Prints ios version if supported otherwise ""
    #
    # msg_2 "host_ios_version(()"
    if [ -f "$f_UIDevice" ]; then
        _os_version="$(tail -n 1 "$f_UIDevice" | sed -n 's/OS Version: \([0-9.]\+\)/\1/p')"
    else
        _os_version=""
    fi
    echo "$_os_version"

    # msg_3 "host_ios_version(() = $_os_version - done"
    unset _os_version
    # msg_3 "host_ios_version(() - done"
}

is_first_vers_str_larger() {
    version1="$1"
    version2="$2"

    [ -z "$version1" ] && error_msg "is_first_vers_str_larger - missing param 1"
    [ -z "$version2" ] && error_msg "is_first_vers_str_larger - missing param 2"

    # msg_2 "is_first_vers_str_larger($version1,$version2)"

    IFS='.' read -r v1_major v1_minor v1_patch <<EOF
$version1
EOF

    IFS='.' read -r v2_major v2_minor v2_patch <<EOF
$version2
EOF
    if [ "$v1_major" -lt "$v2_major" ]; then
        _result=1 # False
    elif [ -z "$v1_minor" ] && [ -n "$v2_minor" ]; then
        _result=1 # False
    elif [ -n "$v1_minor" ] && [ -z "$v2_minor" ]; then
        _result=0 # True
    elif [ "$v1_minor" -lt "$v2_minor" ]; then
        _result=1 # False
    elif [ -z "$v1_patch" ] && [ -z "$v2_patch" ]; then
        _result=0 # True
    elif [ -z "$v1_patch" ] && [ -n "$v2_patch" ]; then
        _result=1 # False
    elif [ -n "$v1_patch" ] && [ -z "$v2_patch" ]; then
        _result=0 # True
    elif [ "$v1_patch" -lt "$v2_patch" ]; then
        _result=1 # False
    else
        _result=0 # True - default result
    fi

    unset version1
    unset version2
    unset v1_major v1_minor v1_patch
    unset v2_major v2_minor v2_patch
    # msg_3 "is_first_vers_str_larger() - done"
    return "$_result"
}

ios_matching() {
    #
    #  Check if the host iOS version matches
    #
    #  Returns
    #    "Yes"     - compare_vers is same or lower than os_version
    #    "No"      - os_version is higher
    #    "Unknown" - os_version not available
    #
    #  If a second param is given, it is used as the default if platform
    #  doesnt provide os_version
    #
    #  Suggested usage:
    # case "$(ios_matching $_dvc_vers Yes)" in
    # "Yes") _msg="$_dvc_vers ok" ;;
    # "No") _msg="$_dvc_vers NOT" ;;
    #  *) _msg="host os version unknown" ;;
    #  esac
    #
    # msg_2 "ios_matching(()"
    compare_vers="$1"
    s_unknown="${2:-Unknown}"

    [ -z "$compare_vers" ] && error_msg "ios_matching() needs a param"

    os_version="$(host_ios_version)"

    # error_msg "os_version [$os_version] compare_vers [$compare_vers]"
    #
    #  if os_version is not supported by the device this check will allways
    #  fail, since we cant gurantee a min version
    #  If you check for a min version, but the default is to do it if
    #  vers info is not available add an [ -n "$(host_ios_version)" ] condition
    #
    if [ -z "$os_version" ]; then
        echo "$s_unknown"
    elif is_first_vers_str_larger "$os_version" "$compare_vers"; then
        echo "Yes"
    else
        echo "No"
    fi
    unset compare_vers
    unset os_version
    # msg_4 "ios_matching(() - done"
}

# <
# host_os
# host_ios_version

# f_host_os_info=/proc/ish/version
# if [ -f "f_host_os_info" ]; then
#     # bla bla is for code i didnt
#     # have time to enter yet
#     host_device="bla bla iPadOS"
#     host_vers="bla bla 16.6"
# else
#     host_device="Unknown"
#     host_vers="0.0"
# fi

#===============================================================
#
#   Main
#
#===============================================================

#  This just checks a random variable that is defined in utils.sh
#  shellcheck disable=SC2154
[ -z "$pidfile_do_chroot" ] && {
    echo "ERROR: utils.sh must be sourced before vers_checks.sh"
    exit 1
}

#
#  For iSH-AOK release >= 500 this file contains the following two lines
#  about tne device where iSH is running:
#    Model: iPad
#    OS Version: 0.0
#  Regular iSH doesnt support iOS version yet
#
f_UIDevice="$d_build_root"/proc/ish/UIDevice

if [ ! -f "$f_UIDevice" ]; then
    #
    #  Reglar iSH doesnt support this, so will have to guestemate
    #
    f_UIDevice="$d_build_root"/etc/opt/AOK/fake_UIDevice
    [ ! -f "$f_UIDevice" ] && create_fake_dev_details
fi
