# TODO

- Generating bzip2 images only results in very moderate size reductions
should be investigated to hopefully generate smaller images.

## Debian

Allow local login without password, sshd will block it over the net
/etc/pam.d/common-auth   nnullok_secure -> nullok


## /etc/motd

check pam settings to see if ithelps

## runbg

use posix script for Debian/Devuan

## idev_ip

 1 MB in Debian
56 kb in Alpine

Room for optimizing the Debian compile?

## Uncertain issues

### Debian setup

Early on there is an error msg

`mount: /proc/mounts: parse error at line 3 -- ignored`

I have only seen it once, so for now assumed to be a one-off glitch...
