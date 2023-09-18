# TODO

## Wait for bootup to complete

This could be used from /etc/profile for bash/ash and from /etc/zprofile for zsh

It needs to be cheap enough to not noticeably delay future login shells
Here are my current ideas

- Simplest, but assumes runbg is an active service...
Check if /run/openrc/options/runbg/pidfile exists and is newer than /run/runlevel
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



##  Make it more clear how to refer to self during deploy


When the deploy starts its pretty clear what `hostfs_is_alpine` and
`destfs_is_alpine` is refering to. However when the destfs boots up and
does a large part of the deploy itself, shouldnt it be the host?

Perhaps it should be seen as a chroot thing. If something is working
chrooted on a buildhot it would make most sense to see that as a
destfs in this context, but if the same deploy steps happens on the
deploy target, running the deploy as its primary env it would ssem to be
the hostfs. More clarity about how to refer to different roles needs to
be found.


## iSH Debian

When prebuilding /etc/opt/AOK is created in the host FS prior to chroot
