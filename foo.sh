#!/bin/sh

#  Allowing this to be run from anywhere using path
current_dir=$(cd -- "$(dirname -- "$0")" && pwd)

#
#  Automatic sudo if run by a user account, do this before
#  sourcing tools/utils.sh !!
#
#  shellcheck disable=SC1091
. "$current_dir"/tools/run_as_root.sh

if true; then
    #  shellcheck disable=SC1091
    . "$current_dir"/tools/utils.sh
else

echo "Using local deffinitions of destfs"
echo
destfs_alpine="Alpine"
destfs_debian="Debian"
destfs_devuan="Devuan"
destfs_select="select"
destfs_select_hint="$build_root_d"/etc/opt/select_distro

destfs_is_devuan() {
    test -f "$build_root_d"/etc/devuan_version
}
destfs_is_debian() {
    test -f "$build_root_d"/etc/debian_version && ! destfs_is_devuan
}

destfs_is_alpine() {
    ! destfs_is_select && test -f "$file_alpine_release"
}

destfs_is_select() {
    [ -f "$destfs_select_hint" ]
    # [ -f "$build_root_d"/etc/profile ] && grep -q select_distro "$build_root_d"/etc/profile
}

destfs_detect() {
    #
    #  Since a select env also looks like Alpine, this must fist
    #  test if it matches the test criteria
    #
    if destfs_is_alpine; then
        echo "$destfs_alpine"
    elif destfs_is_select; then
        echo "$destfs_select"
    elif destfs_is_debian; then
        echo "$destfs_debian"
    elif destfs_is_devuan; then
        echo "$destfs_devuan"
    else
        # error_msg "destfs_detect() - Failed to detect dest FS"
        echo
    fi
}

fi


destfs_select_hint=

echo "build_root_d [$build_root_d]"




destfs_is_alpine && echo "is alpine" || echo "NOT alpine"
destfs_is_select && echo "is select" || echo "NOT select"
destfs_is_devuan && echo "is devuan" || echo "NOT devuan"
destfs_is_debian && echo "is debian" || echo "NOT debian"
echo "Detected: [$(destfs_detect)]"

