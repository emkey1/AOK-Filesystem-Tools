#!/usr/bin/env bash

PATH=/root/img_build/bin:$PATH

cd /root/img_build/bin || {
    echo
    echo "ERROR: failed to cd /root/img_build/bin"
}

minim_img_prepare.sh
bash
