#!/usr/bin/env bash
#
#  Part of https://github.com/jaclu/AOK-Filesystem-Tools
#
#  Copyright (c) 2023: Jacob.Lundqvist@gmail.com
#
#  License: MIT
#
#  lists the entire file tree, then does a global
#  reverse sort, in order to process most recently
#  changed files first.
#
#  For those types that a linter is defined, linting is done
#  in the order the files are found. This means the last changed
#  file is the first to be checked.
#
#  Identified file types are gathered and listed once lenting is
#  completed
#


#
#  Display error, and exit if exit code > -1
#
error_msg() {
    local em_msg="$1"
     local em_exit_code="${2:-1}"
    if [[ -z "$em_msg" ]]; then
        echo
        echo "error_msg() no param"
        exit 9
    fi

    echo
    echo "ERROR: $em_msg"
    echo
    [[ "$em_exit_code" -gt -1 ]] && exit "$em_exit_code"
}


#
#  Function to sort an array in ascending order
#
sort_array() {
    local input_array=("$@")  # Convert arguments into an array
    local sorted_array=()

    # Use a loop to add each eOBlement to the sorted array
    for item in "${input_array[@]}"; do
        sorted_array+=("$item")
    done

    # Use the POSIX sort utility to sort the array in place
    IFS=$'\n' sorted_array=($(printf "%s\n" "${sorted_array[@]}" | sort))

    echo "${sorted_array[@]}"
}

#
#  Function to check if a string is in an array
#
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


#
#  Scan for and define usable linters
#
identify_available_linters() {
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
}


#===============================================================
#
#   Process files
#
#===============================================================

process_file_tree() {

    #
    #  Loop over al files, first doing exludes
    #  Then identifying filetype using: file -b
    #  grouping by type, and linting files suitable for such
    #  as they come up. Thereby minimizing pointless wait time, since
    #  the file tree is globally sorted by age
    #

    #
    #  Reads in all files, globally reverse sorted by file age
    #
    mapfile -t all_files < <(find . -type f -printf "%T@ %p\n" | sort -n -r -k1,1 | cut -d' ' -f2)

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
	    #do_posix_check "$fname"
            continue
	elif [[ "$f_type" == *"Bourne-Again shell script"* ]]; then
            items_bash+=("$fname")
	    #do_bash_check "$fname"
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
	elif [[ "$f_type" == *"ELF 64-bit LSB"* ]]; then
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
	    #
	    #  For unhandled file types, ignore the file, just store the new file type
	    #  to a list.
	    #
            file_types+=("$f_type")
	    echo "Unhandled file: $fname"
	fi
    done
}


#===============================================================
#
#   Lint specific file types
#
#===============================================================

do_posix_check() {
    local f="$1"
    [[ -z "$f" ]] && error_msg "do_posix_check() - no paran given!" 1
    echo "checking posix: $f"
    if [[ -n "${do_shellcheck}" ]]; then
        # -x follow source
        shellcheck -a -o all -e SC2250,SC2312 "$f" || exit 1
    fi
    if [[ -n "${do_checkbashisms}" ]]; then
        checkbashisms -n -e -x "$f" || exit 1
    fi
}

do_bash_check() {
    local f="$1"
    [[ -z "$f" ]] && error_msg "do_bash_check() - no paran given!" 1
    echo "checking bash: $f"
    if [[ -n "${do_shellcheck}" ]]; then
        shellcheck -a -o all -e SC2250,SC2312 "$f" || exit 1
    fi
}

#===============================================================
#
#   Display a given type in sorted order
#
#===============================================================

list_item_group() {
    local lbl="$1"
    shift
    local items=("$@")
    [[ -z "$items" ]] && return
    echo
    echo "---  $lbl  ---"
    for item in $(sort_array "${items[@]}"); do
	echo "$item"
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

#===============================================================
#
#   Main
#
#===============================================================

prog_name=$(basename "$0")

echo "This is $prog_name"
echo

#
#  Ensure this is run in the intended location in case this was launched from
#  somewhere else.
#
cd /opt/AOK || error_msg "The AOK file tools needs to be saved to /opt/AOK for things to work!" 1



#
#  Specifix excludes
#
excludes=(
    ./Alpine/cron/15min/dmesg_save
    ./Debian/etc/profile
    ./common_AOK/usr_local_bin/aok
    ./tools/not_used.sh
)

#
#  Excludes by prefix/suffix
#
prefixes=(
    ./.git
    ./.vscode
    ./Devuan/etc/update-motd.d
)
suffixes=(
    \~
)

process_file_tree

echo "---------------------------------------------------------------"

#
#  Display selected file types
#


#list_item_group bash      "${items_bash[@]}"
#list_item_group posix     "${items_posix[@]}"

#list_item_group "ASCII text"  "${items_ascii[@]}"
#list_item_group perl      "${items_perl[@]}"
#list_item_group c         "${items_c[@]}"
#list_item_group makefile  "${items_makefile[@]}"
#list_item_group json    "${items_json[@]}"
#list_item_group openrc    "${items_openrc[@]}"
#list_item_group "Unicode text, UTF-8 text"     "${items_ucode[@]}"
#list_item_group "Unicode text, UTF-8 text, with escape" "${items_ucode_esc[@]}"

#list_item_group "ELF 32-bit LSB pie executable, Intel 80386, version 1 (SYSV), dynamically linked, interpreter /lib/ld-linux.so.2" "${items_bin32_linux_so[@]}"
#list_item_group "ELF 32-bit LSB pie executable, Intel 80386, version 1 (SYSV), dynamically linked, interpreter /lib/ld-musl-i386" "${items_bin32_musl[@]}"

#
#  Make sure no bin64 items are pressent!
#
#if [[ -n "$items_bin64" ]]; then
#    echo
#    echo "***  iSH can not run 64-bit bins, this is a problem!  ***"
#    list_item_group "ELF 64-bit LSB executable" "${items_bin64[@]}"
#fi

list_file_types
#if [[ -n "$file_types" ]]; then
#    list_item_group "ELF 64-bit LSB executable" "${file_types[@]}"
#fi
