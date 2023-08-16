#!/bin/sh

#
#  if current script was started by user account, execute again as root
#
#  This should be sourced, in order for the environment to point
#  to the initial script, so that the right thing gets started
#
#  Sample usage case, ensuring that the initial script can be
#  run with a path, not only from same dir.
#  Note that in order to find run_as_root.sh you need to
#  for each script using this approach ensure that it is found
#  in relationship to current_dir from the perspective of the one
#  soucring run_as_root.sh
#
#   #  Allowing the script to be run from anywhere using path
#   current_dir=$(cd -- "$(dirname -- "$0")" && pwd)
#   . "$current_dir"/tools/run_as_root.sh
#
#  Simplest usage case, assume caller of the initial script is in
#  the right/expected path
#
#   # auto sudo this script if run by user
#   . tools/run_as_root.sh
#
#  If you do not want to get the: Executing $app as root
#  printout preceede your commant or the sourcing with: hide_run_as_root=1
#

app="$0"
[ -z "$app" ] && {
    echo "ERROR: No param zero indicating what to run!"
    exit 1
}
if [ "$(whoami)" != "root" ]; then
    #  shellcheck disable=SC2154
    if [ -z "$hide_run_as_root" ]; then
        echo "Executing $app as root"
        echo
    fi
    #  using $0 instead of full path makes location not hardcoded
    sudo TMPDIR="$TMPDIR" "$app" "$@"
    exit_code="$?"

    #  terminate the user initiated instance of the script
    exit "$exit_code"
fi
