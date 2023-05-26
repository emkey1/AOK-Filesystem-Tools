#!/bin/sh

#
#  If you run both aok and regular iSH on the same device
#  this script modifies the hostname for aok kernels to have -aok suffix
#  So my iPad JacPad would be calling itself JacPad-aok if you check
#  `hostname`
#

! is_aok_kernel && return #  Only relevant for aok kernels
[ "$AOK_HOSTNAME_SUFFIX" != "Y" ] && return

msg_1 "Setting -aok suffix for hostname"

orig_hostname="$(hostname)"
new_hostname="${orig_hostname}-aok"
initd_hostname="/etc/init.d/hostname"

if is_debian; then
    msg_3 "Removing previous service files"
    rm -f /etc/init.d/hostname
    rm -f /etc/init.d/hostname.sh
    rm -f /etc/rcS.d/S01hostname.sh
    rm -f /etc/systemd/system/hostname.service
fi

msg_2 "Changing hostname into: $new_hostname"
sed s/NEW_HOSTNAME/"$new_hostname"/ "$DEPLOY_PATH"/files/init.d/aok-hostname-service >"$initd_hostname"
chmod 755 "$initd_hostname"
ensure_service_is_added hostname boot
"$initd_hostname" restart
msg_3 "Hostname now is:$(hostname)"
#
#  Since hostname was changed, configs need to be read again,
#  in order to pick up the config for this renamed hostname
#
msg_1 "Changed hostname - re-reading config"
read_config
