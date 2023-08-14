#!/usr/bin/env bash
#
#  Part of https://github.com/jaclu/AOK-Filesystem-Tools
#
#  Copyright (c) 2023: Jacob.Lundqvist@gmail.com
#
#  License: MIT
#
#  Runs shellcheck on all included scripts
#

prog_name=$(basename "$0")

echo "$prog_name"
echo

#
#  Ensure this is run in the intended location in case this was launched from
#  somewhere else.
#
cd /opt/AOK || {
    echo
    echo "ERROR: The AOK file tools needs to be saved to /opt/AOK for things to work!".
    echo
    exit 1
}

do_shellcheck="$(command -v shellcheck)"
do_checkbashisms="$(command -v checkbashisms)"

if [[ "${do_shellcheck}" = "" ]] && [[ "${do_checkbashisms}" = "" ]]; then
    echo "ERROR: neither shellcheck nor checkbashisms found, can not proceed!"
    exit 1
fi

printf "Using: "
if [[ -n "${do_shellcheck}" ]]; then
    printf "%s " "shellcheck"
fi
if [[ -n "${do_checkbashisms}" ]]; then
    printf "%s " "checkbashisms"
    #  shellcheck disable=SC2154
    if [[ "$build_env" -eq 1 ]]; then
        if checkbashisms --version | grep -q 2.21; then
            echo
            echo "WARNING: this version of checkbashisms runs extreamly slowly on iSH!"
            echo "         close to a minute/script"
        fi
    fi
fi
printf "\n\n"

#!/bin/bash

# Function to check if a string is in an array
string_in_array() {
    local target="$1"
    shift
    local array=("$@")

    for element in "${array[@]}"; do
        if [[ "$element" == "$target" ]]; then
            return 0 # Found the string in the array
        fi
    done

    return 1 # String not found in the array
}

do_posix_check() {
    echo "checking posix: $fname"
    if [[ -n "${do_shellcheck}" ]]; then
        # -x follow source
        shellcheck -a -o all -e SC2250,SC2312 "${fname}" || exit 1
    fi
    if [[ -n "${do_checkbashisms}" ]]; then
        checkbashisms -n -e -x "${fname}" || exit 1
    fi
}

do_bash_check() {
    echo "checking bash: $fname"
    if [[ -n "${do_shellcheck}" ]]; then
        shellcheck -a -o all -e SC2250,SC2312 "${fname}" || exit 1
    fi
}

do_posix() {
    echo
    echo "---  Posix  ---"
    for fname in "${items_posix[@]}"; do
        do_posix_check "$fname"
    done
}

do_bash() {
    echo
    echo "---  Bash  ---"
    for fname in "${items_bash[@]}"; do
        do_bash_check "$fname"
    done
}

do_openrc() {
    [[ -z "$items_openrc" ]] && return
    echo
    echo "---  openrc  ---"
    for fname in "${items_openrc[@]}"; do
        echo "$fname"
    done
}

do_json() {
    [[ -z "$items_json" ]] && return
    echo
    echo "---  json  ---"
    for fname in "${items_json[@]}"; do
        echo "$fname"
    done
}

do_perl() {
    [[ -z "$items_perl" ]] && return
    echo
    echo "---  perl  ---"
    for fname in "${items_perl[@]}"; do
        echo "$fname"
    done
}

do_ucode_esc() {
    echo
    echo "---  Unicode text, UTF-8 text, with escape  ---"
    for fname in "${items_ucode_esc[@]}"; do
        echo "$fname"
    done
}

do_ucode() {
    echo
    echo "---  Unicode text, UTF-8 text  ---"
    for fname in "${items_ucode[@]}"; do
        echo "$fname"
    done
}

do_c() {
    echo
    echo "---  C  ---"
    for fname in "${items_c[@]}"; do
        echo "$fname"
    done
}

do_makefile() {
    echo
    echo "---  makefile script  ---"
    for fname in "${items_makefile[@]}"; do
        echo "$fname"
    done
}

do_ascii() {
    echo
    echo "---  ASCII text  ---"
    for fname in "${items_ascii[@]}"; do
        echo "$fname"
    done
}
do_bin32_linux_so() {
    echo
    echo "---  ELF 32-bit LSB pie executable, Intel 80386, version 1 (SYSV), dynamically linked, interpreter /lib/ld-linux.so.2  ---"
    for fname in "${items_bin32_linux_so[@]}"; do
        echo "$fname"
    done
}

do_bin32_musl() {
    echo
    echo "---  ELF 32-bit LSB pie executable, Intel 80386, version 1 (SYSV), dynamically linked, interpreter /lib/ld-musl-i386  ---"
    for fname in "${items_bin32_musl[@]}"; do
        echo "$fname"
    done
}

do_bin64() {
    [[ -z "$items_bin64" ]] && return
    echo
    echo "***  iSH can not run 64-bit bins, this is a problem!  ***"
    echo
    echo "---  ELF 64-bit LSB executable  ---"
    for fname in "${items_bin64[@]}"; do
        echo "$fname"
    done
}

list_file_types() {
    [[ -z "$file_types" ]] && return
    echo
    echo "---  File types found  ---"
    for f_type in "${file_types[@]}"; do
        echo "$f_type"
        echo
    done
}

#
#  reverse sort so tools comes first, those files
#  are often edited and most likely to have issues
#
#   find . -type f | sort  -r 
mapfile -t all_files < <(find . | sort -r)
excludes=(
    ./Alpine/cron/15min/dmesg_save
    ./Debian/etc/profile
    ./common_AOK/usr_local_bin/aok
    ./tools/not_used.sh
)

prefixes=(
    ./.git
    ./.vscode
    ./Devuan/etc/update-motd.d
)

suffixes=(
    \~
)

for fname in "${all_files[@]}"; do
    [[ -d "$fname" ]] && continue

    for exclude in "${excludes[@]}"; do
        [[ "$fname" == "$exclude" ]] && continue 2
    done

    for prefix in "${prefixes[@]}"; do
        [[ "$fname" == "$prefix"* ]] && continue 2
    done

    for suffix in "${suffixes[@]}"; do
        [[ "$fname" == *"$suffix" ]] && continue 2
    done

    f_type="$(file -b "$fname")"

    if [[ "$f_type" == *"POSIX shell script"* ]]; then
        items_posix+=("$fname")
        continue
    elif [[ "$f_type" == *"Bourne-Again shell script"* ]]; then
        items_bash+=("$fname")
        continue
    elif [[ "$f_type" == *"C source"* ]]; then
        items_c+=("$fname")
        continue
    elif [[ "$f_type" == *"openrc-run"* ]]; then
        items_openrc+=("$fname")
        continue
    elif [[ "$f_type" == *"JSON data"* ]]; then
        items_json+=("$fname")
        continue
    elif [[ "$f_type" == *"Perl script"* ]]; then
        items_perl+=("$fname")
        continue
    elif [[ "$f_type" == *"Unicode text, UTF-8 text, with escape"* ]]; then
        items_ucode_esc+=("$fname")
        continue
    elif [[ "$f_type" == *"Unicode text, UTF-8 text"* ]]; then
        #  This must come after items_ucode_esc, otherwise that would eat this
        items_ucode+=("$fname")
        continue
    elif [[ "$f_type" == *"makefile script"* ]]; then
        #  This must come after items_ucode_esc, otherwise that would eat this
        items_makefile+=("$fname")
        continue
    elif [[ "$f_type" == *"ELF 64-bit LSB executable"* ]]; then
        #  This must come after items_ucode_esc, otherwise that would eat this
        items_bin64+=("$fname")
        continue
    elif [[ "$f_type" == *"ELF 32-bit LSB pie executable, Intel 80386, version 1 (SYSV), dynamically linked, interpreter /lib/ld-linux.so.2"* ]]; then
        #  This must come after items_ucode_esc, otherwise that would eat this
        items_bin32_linux_so+=("$fname")
        continue
    elif [[ "$f_type" == *"ELF 32-bit LSB pie executable, Intel 80386, version 1 (SYSV), dynamically linked, interpreter /lib/ld-musl-i386"* ]]; then
        #  This must come after items_ucode_esc, otherwise that would eat this
        items_bin32_musl+=("$fname")
        continue
    elif [[ "$f_type" == *"ASCII text"* ]]; then
        #  This must come after items_ucode_esc, otherwise that would eat this
        items_ascii+=("$fname")
        continue

    elif ! string_in_array "$f_type" "${file_types[@]}"; then
        file_types+=("$f_type")
    fi
    #
    # Display uncathegorized
    #
    #[[ "$f_type" != *"ELF"* ]] && {
    # 	file "$fname"
    #	echo
    #}
done

do_bash
do_posix

do_ascii
do_perl
do_json
do_c
do_makefile
do_openrc
do_ucode
do_ucode_esc

#do_bin32_linux_so
#do_bin32_musl
# Make sure no bin64 items are pressent!
do_bin64

list_file_types
