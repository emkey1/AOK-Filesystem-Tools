#!/usr/bin/env bash

# shellcheck source=/dev/null
source /opt/AOK/tools/utils.sh

process_custom_file_list() {
    files_template="$1"
    [[ -z "$files_template" ]] && error_msg "process_custom_file_list() no param"

    msg_2 "process_custom_file_list($files_template)"
    source "$files_template"

    # Iterate over the array
    while [[ ${#file_list[@]} -gt 0 ]]; do
        src_file="${file_list[0]}"
        dst_file="${file_list[1]}"
        owner="${file_list[2]}"

        #  param checks
        [[ -z "$src_file" ]] && error_msg "process_custom_file_list() src_file empty"
        [[ -z "$dst_file" ]] && error_msg "process_custom_file_list() dst_file empty"

        if [[ ! -f "$src_file" ]]; then
            error_msg "$files_template, src_file not found: $src_file"
        fi
        cp -av "$src_file" "$dst_file"
        if [[ -n "$owner" ]]; then
            msg_3 "Changing ownership for $dst_file - $owner"
            chown "$owner" "$dst_file"
        fi

        #  Remove the first item from the array
        file_list=("${file_list[@]:3}")
    done
    # msg_3 "process_custom_file_list($files_template) - done"
}

if destfs_is_alpine && [[ -n "$ALPINE_CUSTOM_FILES_TEMPLATE" ]]; then
    process_custom_file_list "$ALPINE_CUSTOM_FILES_TEMPLATE"
fi

if destfs_is_debian && [[ -n "$DEBIAN_CUSTOM_FILES_TEMPLATE" ]]; then
    process_custom_file_list "$DEBIAN_CUSTOM_FILES_TEMPLATE"
fi
