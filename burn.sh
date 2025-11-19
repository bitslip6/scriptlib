#!/usr/bin/env zsh
# or: #!/usr/bin/env bash

# load up our color values and our general library
. "$(dirname "$0")/colors.sh"
. "$(dirname "$0")/libs.sh"

list_removable_devices_linux() {
    local dev sysdir removable line name
    local num_files width counter

    num_files=$(file_count "/sys/block")
    width=60
    counter=0

    for sysdir in /sys/block/*; do
        counter=$((counter + 1))
        progress_indicator "scanning disks ($counter) ..." "$counter" "$num_files" "$width" >&2

        dev=$(basename "$sysdir")
        [ -e "$sysdir/removable" ] || continue

        removable=$(cat "$sysdir/removable" 2>/dev/null)
        [ "$removable" = "1" ] || continue  # only removable devices

        line=$(lsblk -dn -o NAME,SIZE,MODEL,LABEL "/dev/$dev" 2>/dev/null)
        [ -n "$line" ] || continue

        # line looks like: "sdb 29.3G SanDisk_Ultra label"
        name=${line%% *}

        # value|label format for picker:
        # value: /dev/sdb
        # label: /dev/sdb 29.3G SanDisk_Ultra label
        printf '%s|%s\n' "/dev/$name" "/dev/$line"
    done

    # final full bar
    progress_indicator "scanning disks ($counter) ..." "$num_files" "$num_files" "$width" >&2
}



#
# return a list of removeable media on linux with info about the media
list_removable_devices_linux_del() {
    local dev sysdir removable line

    local num_files=($(file_count "/sys/block"))
    local width="40"

    #rogress_indicator "Testing progress..." "$i" "$total" "$width"
    conuter=1
    for sysdir in /sys/block/*; do
        counter=$((counter + 1))
        progress_indicator "scanning disks ..." "$counter" "$num_files" "$width" >&2
        dev=$(basename "$sysdir")
        [ -e "$sysdir/ro" ] || continue

        removable=$(cat "$sysdir/removable" 2>/dev/null)
        [ "$removable" = "0" ] || continue

        line=$(lsblk -dn -o NAME,SIZE,MODEL,LABEL "/dev/$dev" 2>/dev/null)
        [ -n "$line" ] || continue

        printf '%s\n' "/dev/$line"
    done
    progress_indicator "scanning disks ..." "$counter" "$num_files" "$width" >&2
}

 
#
# return a list of removeable media on FreeBSD with info about the media
list_removable_devices_freebsd() {
    local current dev removable size descr ident line

    # Parse "geom disk list" output block by block
    geom disk list | while IFS= read -r line; do

        case "$line" in
            "Geom name:"*)
                # New device block
                current=$(printf '%s' "$line" | awk '{print $3}')
                dev="$current"
                removable=""
                size=""
                descr=""
                ident=""
                ;;
            "      descr:"*)
                descr=$(printf '%s' "$line" | sed 's/.*descr: //')
                ;;
            "      ident:"*)
                ident=$(printf '%s' "$line" | sed 's/.*ident: //')
                ;;
            "      mediasize:"*)
                size=$(printf '%s' "$line" | awk '{print $3}' | numfmt --to=iec 2>/dev/null)
                ;;
            "      removable:"*)
                removable=$(printf '%s' "$line" | awk '{print $2}')
                ;;
            "")
                # End of a device block
                if [ "$removable" = "1" ] && [ -n "$dev" ]; then
                    printf '/dev/%s %s %s %s\n' \
                        "$dev" \
                        "${size:-unknown}" \
                        "${descr:-no_descr}" \
                        "${ident:-no_ident}"
                fi
                ;;
        esac

    done
}

# Usage:
#   stream_image_file "path/to/image.ext"
# It writes the raw image bytes to stdout.
stream_image_file() {
    local image_file="$1"

    if [ -z "$image_file" ]; then
        printf 'stream_image_file: missing file argument\n' >&2
        return 1
    fi

    if [ ! -f "$image_file" ]; then
        printf 'stream_image_file: file not found: %s\n' "$image_file" >&2
        return 1
    fi

    case "$image_file" in
        # plain images
        *.iso|*.img|*.raw|*.bin|*.qcow2)
            cat -- "$image_file"
            ;;
        # xz compressed (includes *.img.xz, *.iso.xz, etc)
        *.xz)
            xz -dc -- "$image_file"
            ;;
        # gzip compressed (*.img.gz, *.iso.gz, etc)
        *.gz)
            gzip -dc -- "$image_file"
            ;;
        # bzip2 compressed
        *.bz2)
            bzip2 -dc -- "$image_file"
            ;;
        # zip archives (assumes single image inside, common for OS downloads)
        *.zip)
            # if there are multiple files inside, this will stream all of them
            # you can tighten this later if needed with an inner file name
            unzip -p -- "$image_file"
            ;;
        # 7z archives
        *.7z)
            7z x -so -- "$image_file"
            ;;
        *)
            # fallback, treat it as a raw file
            cat -- "$image_file"
            ;;
    esac
}




# list_os_images: prints all likely OS image files in the current directory
list_os_images() {
    local f
    local exts="
        iso
        img
        raw
        bin
        qcow2
        dmg
        zip
        xz
        gz
        bz2
        7z
    "

    for f in *; do
        [ -f "$f" ] || continue

        # Check exact or double extensions
        case "$f" in
            *.iso|*.img|*.raw|*.bin|*.qcow2|*.dmg)
                printf '%s\n' "$f"
                ;;
            *.zip|*.xz|*.gz|*.bz2|*.7z)
                printf '%s\n' "$f"
                ;;
            *.iso.*|*.img.*|*.raw.*|*.bin.*)
                printf '%s\n' "$f"
                ;;
        esac
    done
}

# Usage:
#   stream_image_file "path/to/image.ext"
# It writes the raw image bytes to stdout.
stream_image_file() {
    local image_file="$1"

    if [ -z "$image_file" ]; then
        printf 'stream_image_file: missing file argument\n' >&2
        return 1
    fi

    if [ ! -f "$image_file" ]; then
        printf 'stream_image_file: file not found: %s\n' "$image_file" >&2
        return 1
    fi

    case "$image_file" in
        # plain images
        *.iso|*.img|*.raw|*.bin|*.qcow2)
            cat -- "$image_file"
            ;;
        # xz compressed (includes *.img.xz, *.iso.xz, etc)
        *.xz)
            xz -dc -- "$image_file"
            ;;
        # gzip compressed (*.img.gz, *.iso.gz, etc)
        *.gz)
            gzip -dc -- "$image_file"
            ;;
        # bzip2 compressed
        *.bz2)
            bzip2 -dc -- "$image_file"
            ;;
        # zip archives (assumes single image inside, common for OS downloads)
        *.zip)
            # if there are multiple files inside, this will stream all of them
            # you can tighten this later if needed with an inner file name
            unzip -p -- "$image_file"
            ;;
        # 7z archives
        *.7z)
            7z x -so -- "$image_file"
            ;;
        *)
            # fallback, treat it as a raw file
            cat -- "$image_file"
            ;;
    esac
}




main() {
    local data1 string_to_linesx selected device name image_txt files image


    # Build list of candidate devices
    #devices=($(list_removable_devices_linux))
    #echo "$devices"
    #echo "choose.."
    data1=$(list_removable_devices_linux $1)
    # convert the string to an array on new lines (data2 is an output var 
    string_to_lines data2 "$data1"
    echo
    selected=$(picker_select "Select disk to write to" $data2)

    device=$(split_get "$selected" "|" 0)
    name=$(split_get "$selected" "|" 1)

    image_txt=$(list_os_images)
    string_to_lines files "$image_txt"
    image=$(picker_select "Select image to write to $name" $files)


    echo "stream_image_file $image | pv | sudo dd of=$device bs=4M conv=fsync,noerror"
    stream_image_file $image | pv | sudo dd of=$device bs=4M conv=fsync,noerror

    exit 0
}

main "$@"

