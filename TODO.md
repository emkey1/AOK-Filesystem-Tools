# TODO

- Alpine/etc/motd_template, the embedded urls doesnt seem to work

## INITIAL_LOGIN_MODE

its set to enable, yet ends up being: disable - investigate

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

##  Build status etc

- Check user interactions when pre building
wich can/should happen during PB, and wich should happen at 1b


## New aproach

buildtype_set / buildtype_get


### Build type

Hint on what is being built, helps compress_image to find a create a
filename for the image if none is provided

uses the file f_build_type "$aok_content_etc/build_type"

### Build state

uses the file f_build_state "$aok_content_etc/build_state"

Hint on in what state the deploy is
  - Not started   = a Full deploy needs to happen
  - deploying     = basic deploy in progress
  - is_prepared  = basic deploy is complete, final steps remains

  when final steps complete, this build status and the build type should
  be cleared

### Meta states

hints on various things that might be of importance, should remain in
use after deploy
f_tmux_nav_key_handling="/etc/opt/tmux_nav_key_handling"
should be handled in a compatible way

  - "this_fs_is_chrooted" This is chrooted
  - is being prebuilt



error_msg "debug abort setup_Alpine_on_1st_boot()"

```shell

#
#  temp value until we know if this is dest FS, so that build_root_d can
#  be selected
#
f_build_state_raw="${aok_content_etc}/build_state"
f_this_fs_is_chrooted_raw="/etc/opt/this_fs_is_chrooted"
#
#  status_being_built and build_status, used by bldstat_get()
#  must be defined before this
#
if this_fs_is_chrooted; then
    build_root_d=""
    # msg_1 "build_root_d=$build_root_d - This is chrooted"
elif test -f /etc/opt/AOK-login_method; then
    build_root_d=""
    # msg_1 "build_root_d=$build_root_d - on installed dest platform"
elif test -f "$f_build_state_raw"; then
    build_root_d=""
    # msg_1 "build_root_d=$build_root_d - on dest platform during dploy"
else
    build_root_d="$build_base_d/FS"
    error_msg "Buildroot $build_root_d"
    # msg_1 "build_root_d=$build_root_d - Not chrooted, not dest platform"
fi

#  Now the proper value can be set
# build_status="${build_root_d}${build_status_raw}" # TODO: Delete me
f_build_type="${build_root_d}${aok_content_etc}/build_type"
f_build_state="${build_root_d}${f_build_state_raw}"
f_this_fs_is_chrooted="${build_root_d}${f_this_fs_is_chrooted_raw}"

##  iCloud

argh need to figure out how to get  should_icloud_be_mounted()
to detect that it is called late on a prebuild in order to decide
to investigate if a mount should happen
unsre not onnly root gets selected shell

## iSH Debian

When prebuilding /etc/opt/AOK is created in the host FS prior to chroot
