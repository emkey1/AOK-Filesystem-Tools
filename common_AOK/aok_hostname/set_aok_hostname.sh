#!/bin/sh

#
#  If you run both aok and regular iSH on the same device
#  this script modifies the hostname for aok kernels to have -aok suffix
#  So my iPad JacPad would be calling itself JacPad-aok if you check
#  `hostname`
#

#  shellcheck disable=SC1091
. /opt/AOK/tools/utils.sh

! is_aok_kernel && return #  Only relevant for aok kernels
[ "$AOK_HOSTNAME_SUFFIX" != "Y" ] && exit 0

msg_1 "Setting -aok suffix for hostname"

new_hostname="$(hostname)-aok"
hostname_service="/etc/init.d/hostname"

if is_debian; then
    msg_3 "Removing previous service files"
    rm -f /etc/init.d/hostname
    rm -f /etc/init.d/hostname.sh
    rm -f /etc/rcS.d/S01hostname.sh
    rm -f /etc/systemd/system/hostname.service
fi

msg_2 "Using service to set hostname with -aok suffix"
msg_3 "This might fail during deploy if system wasnt booted with openrc"
msg_3 "Will work normally on next boot."

rm -f "$initd_hostname"
cp /opt/AOK/common_AOK/aok_hostname/aok-hostname-service "$hostname_service"
chmod 755 "$hostname_service"

sudo rc-update add hostname default
sudo rc-service hostname start

msg_2 "Manually setting hostname, so that it is valid during rest of deploy"
echo "$new_hostname" >/etc/hostname
hostname -F /etc/hostname

msg_3 "Hostname is now: $(hostname)"
