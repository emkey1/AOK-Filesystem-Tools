#!/bin/sh
#
#  shellcheck disable=SC2154
#
#  Part of https://github.com/emkey1/AOK-Filesystem-Tools
#
#  License: MIT
#
#  Purpose of this is to ensure TMPDIR is assigned.
#  It defins where most actions on the host platform will be performed.
#
#  It will be assigned as follows:
#
#  1) If AOK_TMPDIR is defined in the env,it will be used
#  2) If TMPDIR is defined in the env, it will be used as is
#  3) It will be set to /tmp
#
#  Internally all the parts of AOK assumes TMPDIR has been set.
#  Since most tools needs to be run as root, they will source
#  tools/run_as_root.sh thereby restarting as root if not so already.
#  That one sources this, so the only times this would need to
#  be directly sourced, is tools not needing to be run as root.
#
#  tools/run_as_root.sh will filter out AOK_TMPDIR before restarting
#  items, otherwise it would risk spilling over when chrooting,
#  for example.
#

# echo ">>> preserve_env.sh starting"
[ -z "$AOK_DIR" ] && {
    echo "ERROR: tools/preserve_env.sh needs AOK_DIR set to base dir of repo"
    exit 1
}

TMPDIR="${AOK_TMPDIR:-${TMPDIR:-/tmp}}"
unset AOK_TMPDIR
