# TODO

## famdeb Mapt installed after apt install/purge

## kernel glitches

## minim install

bc gawk grep procps sed ncurses-bin wget cron whiptail
man-db groff-base rsyslog

## aok install

file less sudo tar util-linux openrc vim curl rsync sqlite3
? groff-base

### /proc/loadavg

causes uptime, htop, top to fail

env & last checked

ish-Debian missing 24-02-19

## remote aok -e off crashes ssh session

Not sure what happens, seems to create at least 3
 /bin/sh /usr/local/bin/aok -e off
processes, ending up non responsive
in most cases new ssh sessions can be created. existing sessions
tends to survive as long as they didnt generate any output whilst
the -e off took place

## Alpine app versions

htop from A 3.14
apk add lua5.3

## vnc-start / stop

Verify the new grep check works as intended

## /etc/environment

Set it with a reasonable PATH

## aok more options

- option for logging console to pts/0
- option for lsunch cmd: default, aok default, custom
- should bat lvl be displayed in colors yes/no
- bat levels default / custom
- bat lvl colors

## Remove obsolete files

Alpine/usr_local_bin/apk-find-pkg.sh it is now apk-find-pkg

## Start working on using a working /run

Investigate if anything can be simplified / needs to be changed given
that /run is now clean at boot time for iSH-AOK, and asuming
dynamic_login is the Launch cmd, this is also the case for regular iSH
hm perhaps this cleanup of /run should be the first inittab task instead?

## make tools/shellchecker.sh a standalone tool

an improvement would be to make it a generic tool, then just keep
something like .shellchecker in the top dir of a project, defining
exclusions

## Seems to be issues with latest  mdcat on 3.18

investigate and if confirmed, try to find latest version that can be used,
and add it to set of custom apks
in Alpine/setup_alpine.sh

## Using /dev/console within the iSH limitations

This actually works much better in Debian than in Alpine, since in Alpine
as of now only auto-login as root works. agetty fails to change ownership
of /dev/pts/0 on Alpine

1 Add this as Launch cmd to avoid harmless but annoying error msg everytime
ish is started and offensive login BEFORE init is run, but still ensure
/dev/pts/0 is bound
`/bin/sleep infinity`

2 Replace console with this alternate content in /usr/local/sbin/fix_dev
if you use it via inittab, otherwise  run it in a shell as root, in order
to ensure anything can print to
/dev/console, without being restricted when agetty locks down /dev/pts/0
With this normal bootup console output can be seen!

```sh
#rm -f /dev/console && mknod -m 666 /dev/console c 5 1
rm -f /dev/console && mknod -m 222 /dev/console c 136 0
```

3a Add this towards end of /etc/inittab if you want a login prompt for
console screen

``` inittab
pts0::respawn:/sbin/agetty pts/0 linux
```

3b Alternatively use this if you want to use -a to login as a user without
prompting for password, be aware that in this case logout / exit will
instantly automatically log you back in again 🙂  You will have to use
shutdown to terminate the iSH app

pts0::respawn:/sbin/agetty -a root pts/0 linux

IMPORTANT UPDATE: Please be aware that in Alpine you cant use pts0 as an
inittab identifier for whatever reason, despite it being no longer than
4 chars, in such cases labeling it as tty1 works and will give you a prompt.
On Debian pts0 works, and makes more sense since it hints what device this
is using

## Wait for bootup to complete

runlevel default should, do, can something else be done if openrc is not used?

This could be used from /etc/profile for bash/ash and from /etc/zprofile
for zsh

It needs to be cheap enough to not noticeably delay future login shells
Here are my current ideas

- Simplest, but assumes runbg is an active service...
Check if /run/openrc/options/runbg/pidfile exists and is newer than
/run/runlevel
- If AOK_HOSTNAME_SUFFIX="Y" and ish-AOK this is quite cheap and quick
`while ! hostname | grep -q '\-aok' ; do`
- Uses ps ax, so has a crash risk, probably not ideal
`while ! ps ax | grep [i]nit | grep -q '\[2\]'; do`

rest of this code block

```sh
    echo "waiting for bootup to complete"
    sleep 2
done
```

## Make it more clear how to refer to self during deploy

When the deploy starts its pretty clear what `hostfs_is_alpine` and
`destfs_is_alpine` is refering to. However when the destfs boots up and
does a large part of the deploy itself, shouldnt it be the host?

Perhaps it should be seen as a chroot thing. If something is working
chrooted on a buildhot it would make most sense to see that as a
destfs in this context, but if the same deploy steps happens on the
deploy target, running the deploy as its primary env it would ssem to be
the hostfs. More clarity about how to refer to different roles needs to
be found.

## Investigate respawn issue

it seems a respawn process only is run once

## /usr/local/sbin/dynamic_login

When used as a Launch cmd, and autologins to a zsh user
the console session is logged out after a copple of minutes  - investigate

- ensure NavKey.md has correct paths

## update DEVUAN_SRC_IMAGE

since it is about to become more usefull, i should update it to ensure it
is in line with the debian image when it comes to what is installed
out of the door
