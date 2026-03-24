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

get_digits_from_string() {
    # this is used to get "clean" integer version number. Examples:
    # `tmux 1.9` => `19`
    # `1.9a`     => `19`

    only_digits="$(echo "$1" | tr -dC '[:digit:]')"
    zero_tailed_to_5_chars="$(printf "%-5s" "$only_digits" | tr ' ' '0')"
    # no_leading_zero=${only_digits#0}
    echo "$zero_tailed_to_5_chars"

    unset only_digits zero_tailed_to_5_chars
}

min_version() {
    # This returns true if v_comp _aok_installed_alpine_vers <=
    v_comp="$(get_digits_from_string "$1")"
    f_v_ref=/tmp/aok_vers_comp_ref

    [ -z "$_aok_installed_alpine_vers" ] && {
        if [ -f "$f_v_ref" ]; then
            _aok_installed_alpine_vers="$(cat "$f_v_ref")"
        else
            _aok_installed_alpine_vers="$(get_digits_from_string "$(cat /etc/alpine-release)")"
            echo "$_aok_installed_alpine_vers" >"$f_v_ref"
        fi
    }

    # this only leaves _b defined
    [ "$v_comp" -le "$_aok_installed_alpine_vers" ] && _b=0 || _b=1
    unset v_comp
    return "$_b"
}

old_min_version() {
    #
    #  Compares version numbers  returns true if $1 <= $2
    #

    # Replace each character with ".<character>" and remove any leading or trailing dots
    _vers1="$(echo "$1" | sed 's/[^.]/.&/g' | sed 's/\.\././g' | sed 's/^\.//;s/\.$//')"
    _vers2="$(echo "$2" | sed 's/[^.]/.&/g' | sed 's/\.\././g' | sed 's/^\.//;s/\.$//')"
    #region vers split
    #
    #  Split versions in its components
    #
    IFS='.' read -r _v1_1 _v1_2 _v1_3 _v1_4 <<-EOF
$_vers1
EOF
    IFS='.' read -r _v2_1 _v2_2 _v2_3 _v2_4 <<-EOF
$_vers2
EOF
    #endregion
    _is_true="" #  Initial non 0 / 1 value makes it simple to see when it is set

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

    [ "$1" = "" ] || [ "$_v1" = "0" ] && {
        _is_true=0
        return 0
    }

    [ "$_v1" -lt "$_v2" ] && {
        _is_true=0
        return 0
    }
    [ "$_v1" = "$_v2" ] && {
        return 0
    }
    [ "$_v1" -gt "$_v2" ] && {
        return 1
    }
    exit 1
}

vers_check_verify() {
    rslt_exp="$1"
    v_ref="$2"
    v_comp="$3"

    min_version "$v_ref" "$v_comp" && rslt_actual=0 || rslt_actual=1
    [ "$rslt_actual" = "$rslt_exp" ] || {
        echo "Failed: $v_ref <= $v_comp should be $rslt_exp - was $rslt_actual"
        exit 1
    }
}

vers_check_check_test() {
    # final null
    vers_check_verify 0 2 2.0
    vers_check_verify 0 2.0 2
    vers_check_verify 0 2.0 2.0

    # basic number
    vers_check_verify 0 3
    vers_check_verify 0 3 3
    vers_check_verify 1 3 2

    vers_check_verify 0 2.1 2.1.1
    vers_check_verify 0 2.1 2.1.0
    vers_check_verify 0 2.1.0 2.1

    vers_check_verify 0 2.3 3
    vers_check_verify 1 2.3 2.2
    vers_check_verify 0 2.3 2.3
    vers_check_verify 0 2.3 2.3

    # nmbers > 9
    vers_check_verify 1 11 10
    vers_check_verify 1 11 10.1
    vers_check_verify 0 11 11
    vers_check_verify 0 11 11.1
    vers_check_verify 0 11 12
}

#
#  Run the tests by calling this directly
#
[ "$(basename "$0")" = "vers_check.sh" ] && vers_check_check_test
