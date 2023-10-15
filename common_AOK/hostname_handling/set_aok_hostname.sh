#!/bin/sh
#
#  If you run both aok and regular iSH on the same device
#  this script modifies the hostname for aok kernels to have -aok suffix
#  So my iPad JacPad would be calling itself JacPad-aok if you check
#  `hostname`
#

. /opt/AOK/tools/utils.sh

#  Only relevant for aok kernels and if AOK_HOSTNAME_SUFFIX is "Y"
#  shellcheck disable=SC2154
if ! this_is_aok_kernel || [ "$AOK_HOSTNAME_SUFFIX" != "Y" ]; then
    msg_2 "AOK_HOSTNAME_SUFFIX will be ignored since this is not iSH-AOK"
    exit 0
fi

if [ -x "$alt_hostname" ]; then

    msg_2 "alternate hostname is used, ignoring AOK_HOSTNAME_SUFFIX"
    exit 0
fi

msg_1 "Setting -aok suffix for hostname"

#  Ensure suffix is not added multiple times if this is restarted
if hostname | grep -q '\-aok'; then
    msg_2 "AOK suffix already set, aborting"
    exit 0
fi

hostname_service="/etc/init.d/hostname"

msg_2 "Using service to set hostname with -aok suffix"
msg_3 "This might fail during deploy if system wasnt booted with openrc"
msg_3 "Will work normally on next boot."

#  This will overwrite the generic hostname service
cp /opt/AOK/common_AOK/hostname_handling/aok-hostname-service "$hostname_service"

msg_3 "hostname service will announce new hostname using: wall -n"

chmod 755 "$hostname_service"
rc-update add hostname default
rc-service hostname start

msg_3 "Hostname is now: $(hostname)"
