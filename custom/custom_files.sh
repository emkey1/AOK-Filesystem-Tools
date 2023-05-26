#!/usr/bin/env bash
# Must be bash, uses arrays...

#
#  Copy user-custom files into selected location
#

#  shellcheck disable=SC1091
. /opt/AOK/tools/utils.sh

process_custom_file_list() {
    files_template="$1"
    [ -z "$files_template" ] && error_msg "process_custom_file_list() no param"

    msg_2 "process_custom_file_list($files_template)"
    source "$files_template"
    # Iterate over the array
    for row in "${file_list[@]}"; do
        if [ "${#row[@]}" -ne 3 ]; then
            error_msg "$files_template - \
                line should contain 3 items, found: $row"
        fi

        src_file="${row[0]}"
        dst_file="${row[1]}"
        owner="${row[2]}"

        if [ ! -f "$src_file" ]; then
            error_msg "$files_template, src_file not found: $src_file"
        fi
        cp -av "$src_file" "$dst_file"
        chown "$owner" "$dst_file"
    done
    msg_3 "process_custom_file_list($files_template) - done"
}

if is_alpine && [[ -n "$ALPINE_CUSTOM_FILES_TEMPLATE" ]]; then
    process_custom_file_list "$ALPINE_CUSTOM_FILES_TEMPLATE"
fi

if is_debian && [[ -n "$DEBIAN_CUSTOM_FILES_TEMPLATE" ]]; then
    process_custom_file_list "$DEBIAN_CUSTOM_FILES_TEMPLATE"
fi
