#!/bin/sh

#
#  Internally all the parts of AOK assumes TMPDIR has been set
#  Since many tools needs to be run as root, they will source
#  tools/run_as_root.sh thereby restarting as root if not so already.
#
#  In case AOK should use a separate TMPDIR, this can be set in AOK_TMPDIR
#  if found TMPDIR will use this.
#  After this point AOK_TMPDIR as such is no longer needed,
#  and if something is sudoed by run_as_root.sh AOK_TMPDIR is not preserved
#
#  For this to work as expected relevant env settings need to be supplied
#  when something is re-run using sudo.
#

# echo ">>> preserve_env.sh starting"

[ -z "$AOK_DIR" ] && {
    echo "ERROR: tools/preserve_env.sh needs AOK_DIR set to base dir of repo"
    exit 1
}

TMPDIR="${AOK_TMPDIR:-${TMPDIR:-/tmp}}"
