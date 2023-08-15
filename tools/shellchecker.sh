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
    local input_array=("$@") # Convert arguments into an array
    local sorted_array=()

    # Use a loop to add each eOBlement to the sorted array
    for item in "${input_array[@]}"; do
        sorted_array+=("$item")
    done

    # Use the POSIX sort utility to sort the array in place
    #IFS=$'\n' sorted_array=($(printf "%s\n" "${sorted_array[@]}" | sort))
    mapfile -t sorted_array < <(printf "%s\n" "${sorted_array[@]}" | sort -f)

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
    if [[ -n "$do_shellcheck" ]]; then
        v_sc="$(shellcheck -V | grep version: | awk '{ print $2 }')"
        if [[ "$v_sc" = "0.5.0" ]]; then
            error_msg "shellcheck to old to be usable" 1
        fi
    fi

    if [[ "$hour_limit" !=  "0" ]]; then

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
    fi
}

#===============================================================
#
#   Lint specific file types
#
#===============================================================

lint_posix() {
    local f="$1"
    lnt_p=1
    [[ -z "$f" ]] && error_msg "lint_posix() - no paran given!" 1
    echo "checking posix: $f"
    if [[ -n "${do_shellcheck}" ]]; then
        lnt_p1=1
        # -x follow source
        #
        shellcheck -a -o all -e SC2250,SC2312 "$f" || exit 1
    fi
    if [[ -n "${do_checkbashisms}" ]]; then
        lnt_p2=1
        checkbashisms -n -e -x "$f" || exit 1
    fi
}

lnt_p=0
lnt_p1=0
lnt_p2=0

lint_bash() {
    local f="$1"
    lnt_b=1
    [[ -z "$f" ]] && error_msg "lint_bash() - no paran given!" 1
    echo "checking bash: $f"
    if [[ -n "${do_shellcheck}" ]]; then
        lnt_b1=1
        shellcheck -a -o all -e SC2250,SC2312 "$f" || exit 1
    else
        echo "shellcheck not available"
    fi
}
lnt_b=0
lnt_b1=0

lint_usage() {
    [[ "$hour_limit" = "0" ]] && return
    echo
    [[ $lnt_p -eq 0 ]] && echo "Warning lint_posix() never called"
    [[ $lnt_p1 -eq 0 ]] && echo "posix shellcheck never called"
    [[ $lnt_p2 -eq 0 ]] && echo "posix checkbashisms never called"

    [[ $lnt_b -eq 0 ]] && echo "Warning lint_bash() never called"
    [[ $lnt_b1 -eq 0 ]] && echo "bash shellcheck never called"
}

get_file_age() {
    local fname="$1"
    if [[ $(uname) == "Darwin" ]]; then
        # macOS version
        stat -f "%m" "$fname"
    else
        # Linux version
        stat -c "%Y" "$fname"
    fi
}

should_it_be_linted() {
    local current_time
    local span_in_seconds

    [[ -z "$hour_limit" ]] && return 0
    if [[ -z "$cutoff_time" ]]; then
	current_time=$(date +%s)  # Get current time in seconds since epoch
	span_in_seconds="$(( 3600 * hour_limit ))"
	cutoff_time="$((current_time - span_in_seconds))"
    fi
    [[ $(get_file_age "$fname") -ge $cutoff_time ]]
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
    #mapfile -t all_files < <(find . -type f -printf "%T@ %p\n" | sort -n -r -k1,1 | cut -d' ' -f2)


    #
    #  But of course find in MacOS does not behave like the rest of them..
    #
    #  MacOS  all 27s
    #  hetz1 linux mode 19s
    #        mac mode
    #
    if [[ $(uname) == "Darwin" ]]; then
        # macOS version
        mapfile -t all_files < <(find . -type f -exec stat -f "%m %N" {} + | sort -nr -k1,1 | cut -d' ' -f2-)
        # find . -type f -exec stat -f "%m %N" {} + | sort -nr -k1,1 | cut -d' ' -f2-
    else
        # Linux version
        mapfile -t all_files < <(find . -type f -printf "%T@ %p\n" | sort -n -r -k1,1 | cut -d' ' -f2)
    fi

    
    #
    #  Works on older versions
    #
    # all_files=($(find . -type f -printf "%T@ %p\n" | sort -n -r -k1,1 | cut -d' ' -f2))

    for fname in "${all_files[@]}"; do
        #[[ "$fname" =
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

        #
        #  To handle a new file type, just repeat one of the below blocs
        #  lets say you identify Python files and want to track them
        #  add the file to something like items_python  in order to pressent
        #  them just make a call like this:
        #    list_item_group "Python" "${items_python[@]}"
        #
        if [[ "$f_type" == *"POSIX shell script"* ]]; then
            items_posix+=("$fname")
	    should_it_be_linted && lint_posix "$fname"
            continue
        elif [[ "$f_type" == *"Bourne-Again shell script"* ]]; then
            items_bash+=("$fname")
	    should_it_be_linted && lint_bash "$fname"
            continue
        elif [[ "$f_type" == *"C source"* ]]; then
            items_c+=("$fname")
            continue
        elif [[ "$f_type" == *"openrc-run"* ]]; then
            items_openrc+=("$fname")
            continue
        elif [[ "$f_type" == *"Perl script"* ]]; then
            items_perl+=("$fname")
            continue
        elif [[ "$f_type" == *"Unicode text, UTF-8 text, with escape"* ]] ||
                 [[ "$f_type" == *"UTF-8 Unicode text, with escape"* ]]; then
            #  Who might have guessed on MacOS file -b output looks different...
            items_ucode_esc+=("$fname")
            continue
        elif [[ "$f_type" == *"Unicode text, UTF-8 text"* ]] ||
                 [[ "$f_type" == *"UTF-8 Unicode text"* ]]; then
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
            #  This must come after items_ucode_esc, otherwise this
            #  very generic string would match most files
            items_ascii+=("$fname")
            continue
        elif ! string_in_array "$f_type" "${file_types[@]}"; then
            #
            #  For unhandled file types, ignore the file, just store the new file type
            #  to a list.
            #
            echo ">>> Unhandled file: $fname" # - $f_type"
            echo ">>> Unhandled type: $f_type"
            file_types+=("$f_type")
        fi
    done
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
    [[ ${#items[@]} -eq 0 ]] && return
    echo
    echo "---  $lbl  ---"
    for item in $(sort_array "${items[@]}"); do
        echo "$item"
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

# Only lint files changed last 24h

if [[ "$1" = "-f" ]]; then
    echo "Will only check files changed in the last 24h"
    echo
    hour_limit=24
fi

if [[ "$1" = "-F" ]]; then
    echo "Will only check files changed in the last 6h"
    echo
    hour_limit=6
fi

if [[ "$1" = "-q" ]]; then
    echo "Will skip any linting, only list files by type"
    echo
    hour_limit=0
fi


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
    ./tools/not_used.sh
)

#
#  Excludes by prefix/suffix
#
prefixes=(
    ./.git
    ./.vscode
)
suffixes=(
    \~
)

identify_available_linters
process_file_tree

#
#  Display selected file types
#

# list_item_group posix "${items_posix[@]}"
# list_item_group bash "${items_bash[@]}"

# list_item_group "ASCII text" "${items_ascii[@]}"
# list_item_group perl "${items_perl[@]}"
# list_item_group C "${items_c[@]}"
# list_item_group makefile "${items_makefile[@]}"
# list_item_group openrc "${items_openrc[@]}"
# list_item_group "Unicode text, UTF-8 text" "${items_ucode[@]}"
# list_item_group "Unicode text, UTF-8 text, with escape" "${items_ucode_esc[@]}"

# list_item_group "ELF 32-bit LSB pie executable, Intel 80386, version 1 (SYSV), dynamically linked, interpreter /lib/ld-linux.so.2" "${items_bin32_linux_so[@]}"
# list_item_group "ELF 32-bit LSB pie executable, Intel 80386, version 1 (SYSV), dynamically linked, interpreter /lib/ld-musl-i386" "${items_bin32_musl[@]}"

#
#  Make sure no bin64 items are pressent!
#
if [[ ${#items_bin64[@]} -gt 0 ]]; then
    echo
    echo "***  iSH can not run 64-bit bins, this is a problem!  ***"
    list_item_group "ELF 64-bit LSB executable" "${items_bin64[@]}"
fi

if [[ ${#file_types[@]} -gt 0 ]]; then
    list_item_group "Unclassified file types" "${file_types[@]}"
fi

lint_usage
