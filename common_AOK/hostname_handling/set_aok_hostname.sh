#!/bin/sh
#
#  Part of https://github.com/jaclu/AOK-Filesystem-Tools
#
#  Copyright (c) 2023: Jacob.Lundqvist@gmail.com
#
#  License: MIT
#
#  If you run both aok and regular iSH on the same device
#  this script modifies the hostname for aok kernels to have -aok suffix
#  So my iPad JacPad would be calling itself JacPad-aok if you check
#  `hostname`
#
#  This will not be installed on dest FS, this is used during deploy
#  to install alternate hostname handling
#

. /opt/AOK/tools/utils.sh

hn_suffix='aok'
hn_alt='/usr/local/bin/hostname'

#  Only relevant if AOK_HOSTNAME_SUFFIX is "Y"
#  shellcheck disable=SC2154
[ "$AOK_HOSTNAME_SUFFIX" != "Y" ] && exit 0

#  Dont hardcode namechange if this is not aok kernel
this_is_aok_kernel || {
    error_msg "set_aok_hostname.sh should not be called if not AOK kernel"
}

[ -x "$hn_alt" ] || error_msg "set_aok_hostname.sh - $hn_alt not installed"

msg_2 "Creating service to set hostname with -$hn_suffix suffix on iSH-AOK"

hostname_service="/etc/init.d/hostname"
#  This will overwrite the generic hostname service
cp /opt/AOK/common_AOK/hostname_handling/aok-hostname-service "$hostname_service"
chmod 755 "$hostname_service"
rc-update add hostname default
#
#  During deploy no point in starting this service, instead set it
#  manually for now
#
# rc-service hostname start

# If hostname -s allready ends with $hn_suffix, nothing needs to be done
if $hn_alt | grep -q "\-$hn_suffix"; then
    msg_2 "AOK suffix (-$hn_suffix) already set in hostname"
    exit 0
fi

msg_2 "Ensuring non suffixed name is in hosts file"
hn_current="$($hn_alt)"
/usr/local/bin/fake_syslog "set_aok_hostname.sh" "Calling ensure_hostname_in_host_file for: $hn_current"
/usr/local/sbin/ensure_hostname_in_host_file

msg_2 "Manually setting -$hn_suffix suffix for hostname for rest of deploy"
#  shellcheck disable=SC2154
/usr/local/bin/fake_syslog "set_aok_hostname.sh" "setting hostname to: $hn_new"
echo "$$hn_new" >/etc/hostname
# Dont use variable, check with alt_hostname to ensure it is set
msg_3 "Hostname is now: $($hn_alt)"
/usr/local/sbin/ensure_hostname_in_host_file
