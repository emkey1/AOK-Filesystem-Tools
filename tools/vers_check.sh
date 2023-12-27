#!/bin/sh
# This will be sourced. Fake bang-path to help editors and linters
#
#  Part of https://github.com/jaclu/iSH-conf.git
#
#  Copyright (c) 2023: Jacob.Lundqvist@gmail.com
#
#  License: MIT
#
#  This provides a version check facility, ensuring that a vers matches
#  the minimal accepted version
#  This also handles version segments with characters mixed in, like
#  tmux style 3.2a
#
#  min_version
#    ref_vers   - this is the minimum accepted version
#    check_vers - this is the version being compared with ref_vers
#
#  returns true (0) if ref_vers <= check_vers
#

min_version() {
    #
    #  Compares version numbers  returns true if $1 <= $2
    #

    # Replace each character with ".<character>" and remove any leading or trailing dots
    _vers1="$(echo "$1" | sed 's/[^.]/.&/g' | sed 's/\.\././g' | sed 's/^\.//;s/\.$//')"
    _vers2="$(echo "$2" | sed 's/[^.]/.&/g' | sed 's/\.\././g' | sed 's/^\.//;s/\.$//')"
    #
    #  Split versions in its components
    #
    IFS='.' read -r _v1_1 _v1_2 _v1_3 _v1_4 <<-EOF
$_vers1
EOF
    IFS='.' read -r _v2_1 _v2_2 _v2_3 _v2_4 <<-EOF
$_vers2
EOF
    #echo "><> min_version($1, $2)  [$_vers1]  [$_vers2]"
    #echo "><> arr1 [$_v1_1] [$_v1_2] [$_v1_3] [$_v1_4]"
    #echo "><> arr2 [$_v2_1] [$_v2_2] [$_v2_3] [$_v2_4]"

    _is_true=""  #  Initial non 0 / 1 value makes it simple to see when it is set

    vers_check_do_compare "$_v1_1" "$_v2_1" || return 1
    [ -n "$_is_true" ] && return 0

    vers_check_do_compare "$_v1_2" "$_v2_2" || return 1
    [ -n "$_is_true" ] && return 0

    vers_check_do_compare "$_v1_3" "$_v2_3" || return 1
    [ -n "$_is_true" ] && return 0

    vers_check_do_compare "$_v1_4" "$_v2_4" || return 1
    return 0
}

#===============================================================
#
#   Rest is internals
#
#===============================================================


vers_check_do_compare() {
    #  Returns True if 1st <= 2nd

    #  Convert characters to ASCII values and inserts 0 if empty
    _v1=$(printf '%d' "'${1:-0}")
    _v2=$(printf '%d' "'${2:-0}")

    #echo "><> vers_check_do_compare($_v1, $_v2)  [$1]  [$2]"

    [ "$1" = "" ] || [ "$_v1" = "0" ] && {
	#echo "><> $_v1 is 0 or empty  0"
	_is_true=0
	return 0
    }

    [ "$_v1" -lt "$_v2" ] && {
	#echo "><> $_v1 -lt $_v2  0"
	_is_true=0
	return 0
    }
    [ "$_v1" = "$_v2" ] && {
	#echo "><> $_v1 = $_v2  0"
	return 0
    }
    [ "$_v1" -gt "$_v2" ] && {
	#echo "><> $_v1 -gt $_v2  1"
	return 1
    }
    #echo "><> fell through"
    exit 1
}

vers_check_verify(){
    v_ref="$1"
    v_comp="$2"
    rslt_exp="$3"

    min_version  "$v_ref" "$v_comp" && rslt_actual=0 || rslt_actual=1
    [ "$rslt_actual" = "$rslt_exp" ] || {
	echo "Failed: $v_ref <= $v_comp should be $rslt_exp - was $rslt_actual"
	exit 1
    }
}


vers_check_check_test() {
    # final null
    vers_check_verify  2     2.0    0
    vers_check_verify  2.0   2      0
    vers_check_verify  2.0   2.0    0

    # basic number
    vers_check_verify  2     1      1
    vers_check_verify  2     2      0
    vers_check_verify  2     3      0

    vers_check_verify  2.1   2.1.1  0
    vers_check_verify  2.1   2.1.0  0
    vers_check_verify  2.1.0 2.1    0

    vers_check_verify  2.3 3        0
    vers_check_verify  2.3 2.2      1
    vers_check_verify  2.3 2.3      0
    vers_check_verify  2.3 2.3      0

    # nmbers > 9
    vers_check_verify 11 10    1
    vers_check_verify 11 10.1  1
    vers_check_verify 11 11    0
    vers_check_verify 11 11.1  0
    vers_check_verify 11 12    0

    # string suffix withot a dot like tmux
    vers_check_verify  2.9 2.9a  0
    vers_check_verify  2.9 2.8a  1
    vers_check_verify  2.9b 2.9  1
    vers_check_verify  2.9b 2.9a 1
    vers_check_verify  2.9b 2.9aa 1
    vers_check_verify  2.9b 2.9b  0
    vers_check_verify  2.9b 2.9ba 0
    vers_check_verify  2.9ab 2.9aa 1
    vers_check_verify  2.9ab 2.9ab 0

    vers_check_verify  2.9a.2 2.9a 1
    vers_check_verify  2.9a.2 2.9b 0
    vers_check_verify  2.9a.2 2.9a.1 1
}

#
#  Run the tests by calling this directly
#
[ "$(basename "$0")" = "vers_check.sh" ] && vers_check_check_test
