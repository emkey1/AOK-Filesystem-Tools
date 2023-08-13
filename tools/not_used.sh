#!/bin/sh

buildstate_param_check() {
    bspc_func="$1"
    [ -z "$bspc_func" ] && error_msg "buildstate_param_check() - no function param!"
    bspc_bs="$2"
    [ -z "$bspc_func" ] && error_msg "buildstate_param_check() - no buildstate param!"

    case "$bspc_bs" in
    "$build_state_not_started" | "$build_state_deploy_1b" | \
        "$build_state_being_prebuilt" | "$build_state_was_prebuilt") ;;
    *) error_msg "${bspc_func}($bspc_bs) - invalid param!" ;;
    esac

    unset bspc_func
    unset bspc_bs
}

buildstate_set() {
    bss_type="$1"
    [ -z "$bss_type" ] && error_msg "buildstate_set() - no param!"

    buildstate_param_check buildstate_set "$bss_type"

    #  This state needs to be preserved, in case compress happens at a
    #  later time
    # echo "bts_type" >
    mkdir -p "$(dirname "$f_build_state")"
    echo "$bss_type" >"$f_build_state"

    unset bss_type
}

buildstate_get() {
    bsg="$(cat "$f_build_state" 2>/dev/null)"
    [ -z "$bsg" ] && return #  nothing set
    echo "$bsg"

    unset bssg
}

buildstate_clear() {
    msg_2 "buildstate_clear()"

    rm "$f_build_state"

    msg_3 "buildstate_clear() - done"
}

#
#  build_state describes deploy method used
#
build_state_not_started="Not started"

# this is a prebuilt, during initial deploy and final steps
build_state_deploy_1b="Deploy on 1st boot"

# this is a prebuilt, during initial deploy and final steps
build_state_being_prebuilt="being pre-built"

#
# indicating that basic deployed happened elswhere, so
# user interactions can take place on first unchrooted
# bootup
#
build_state_was_prebuilt="was pre-built"

#===============================================================
#
#   buildtype
#
#===============================================================
#
#  Setting and checking what buildtype is performed
#  buildtype_get will return "" if not building any more
#

f_build_type="${build_root_d}${aok_content_etc}/build_type"

buildtype_param_check() {
    btpc_func="$1"
    [ -z "$btpc_func" ] && error_msg "buildtype_param_check() - no function param!"
    btpc_bt="$2"
    [ -z "$btpc_func" ] && error_msg "buildtype_param_check() - no buildtype param!"

    case "$btpc_bt" in
    "$destfs_alpine" | "$destfs_debian" | "$destfs_devuan" | "$destfs_select") ;;
    *) error_msg "${btpc_func}($btpc_bt) - invalid param!" ;;
    esac

    unset btpc_func
    unset btpc_bt
}

buildtype_set() {
    msg_2 "buildtype_set($1)"
    #
    #  Sets the buildtype
    #  So that if the resulting FS is later compressed, the apropriate
    #  file name for the image can be auto detected
    #
    bts_type="$1"
    [ -z "$bts_type" ] && error_msg "buildtype_set() - no param!"

    buildtype_param_check buildtype_set "$bts_type"

    #  This state needs to be preserved, in case compress happens at a
    #  later time
    # echo "bts_type" >
    [ -f "$f_build_type" ] && msg_1 "Changing buildtype was:$(buildtype_get) new:$bts_type"

    mkdir -p "$(dirname "$f_build_type")"
    echo "$bts_type" >"$f_build_type"

    unset bts_type
    msg_3 "buildtype_set() - done"
}

buildtype_get() {
    btg="$(cat "$f_build_type" 2>/dev/null)"
    [ -z "$btg" ] && return #  nothing set

    #  Ensure what found is a valid option
    buildtype_param_check buildtype_set "$btg"

    echo "$btg"

    unset btg
}

# ======   From build_fs.sh

clear_build_target() { # Multi OK 1
    msg_2 "clear_build_target()"
    #
    # Clear build env
    #
    if ! rm -rf "$build_base_d"; then
        echo
        echo "ERROR: Could not clear $build_base_d"
        echo
        exit 1
    fi
    # msg_3 "clear_build_target() done"
}

# ======   From utils.sh

compressed_name_get() {
    #
    #  Sets the variable compressed_name based on environment
    #
    # msg_2 "compressed_name_get()"
    if destfs_is_alpine; then
        compressed_name="$destfs_alpine"
    elif destfs_is_debian; then
        compressed_name="$destfs_debian"
    elif destfs_is_devuan; then
        compressed_name="$destfs_devuan"
    else
        error_msg "compressed_name_get() - failed to detect build type"
    fi

    destfs_prebuilding && compressed_name="$compressed_name-pb"

    echo "$compressed_name"
    # msg_3 "compressed_name_get() - done"

    unset compressed_name
}
