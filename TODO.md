# TODO

- Alpine/etc/motd_template, the embedded urls doesnt seem to work

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
