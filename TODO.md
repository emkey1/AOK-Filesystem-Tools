# TODO

## runbg

use posix script for Debian/Devuan

## malloc improvements

xloem provided this snippet, I have not yet fully understood what the
script parts are supposed to do, but I saved it here for further inspection

```bash
sudo apt -y install build-essential cmake git gcc-8-multilib
git clone https://github.com/xloem/mimalloc
cd mimalloc
git checkout vmem
mkdir build
cd build
cmake ..
make
sudo make install
cat <<EOF >/usr/local/bin/mimalloc
#!/usr/bin/env bash
exe="$(type -p "$0")"
while [ -e "$exe" ] && ! [ -e "$exe".orig ]
do
  exe="$(dirname "$exe")"/"$(readlink "$exe")"
done
LD_PRELOAD=/usr/local/lib/libmimalloc.so "$exe".orig "$@"
EOF
for wrapped in /usr/bin/i686-linux-gnu-gcc-8
do
  if ! [ -e “$wrapped”.orig ]
  then
    cp “$wrapped” “$wrapped”.orig
    ln -sf /usr/local/bin/mimalloc “$wrapped”
  fi
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


### remaining

- Alpine - ok
- Debian
- Devuan


## iSH Debian

When prebuilding /etc/opt/AOK is created in the host FS prior to chroot
