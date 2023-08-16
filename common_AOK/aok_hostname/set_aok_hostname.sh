#!/bin/sh
#
#  If you run both aok and regular iSH on the same device
#  this script modifies the hostname for aok kernels to have -aok suffix
#  So my iPad JacPad would be calling itself JacPad-aok if you check
#  `hostname`
#

. /opt/AOK/tools/utils.sh

#  Only relevant for aok kernels and if AOK_HOSTNAME_SUFFIX is "Y"
! this_is_aok_kernel || [ "$AOK_HOSTNAME_SUFFIX" != "Y" ] && exit 0

msg_1 "Setting -aok suffix for hostname"

#  Ensure suffix is not added multiple times if this is restarted
if hostname | grep -q "\-aok"; then
    msg_2 "AOK suffix already set, aborting"
    exit 0
fi

new_hostname="$(hostname)-aok"
hostname_service="/etc/init.d/hostname"

if destfs_is_debian; then
    msg_3 "Debian - removing previous service files"
    rm -f /etc/init.d/hostname
    rm -f /etc/init.d/hostname.sh
    rm -f /etc/rcS.d/S01hostname.sh
    rm -f /etc/systemd/system/hostname.service
fi

msg_2 "Using service to set hostname with -aok suffix"
msg_3 "This might fail during deploy if system wasnt booted with openrc"
msg_3 "Will work normally on next boot."

cp /opt/AOK/common_AOK/aok_hostname/aok-hostname-service "$hostname_service"

msg_3 "hostname service will announce new hostname using: wall -n"

chmod 755 "$hostname_service"
rc-update add hostname default
rc-service hostname start

msg_2 "Manually setting hostname, so that it is valid during rest of deploy"
echo "$new_hostname" >/etc/hostname
hostname -F /etc/hostname

msg_3 "Hostname is now: $(hostname)"
