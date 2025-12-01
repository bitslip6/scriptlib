# libs.sh
# collection of shell functions for use in script writting


# list directory on remote system.
# param 1: target: user@host:/path/to/directory
# param 2 (optional): regular expression to limit listing to
remote_ls() {
    local target="$1"
    local pattern="$2"

    if [ -z "$target" ]; then
        echo "usage: remote_ls user@host:/path [optional_regex]"
        return 1
    fi

    # split into host and path
    local host="${target%%:*}"
    local path="${target#*:}"

    echo "ssh from path: $PATH"

    if [ -n "$pattern" ]; then
        /usr/bin/ssh "$host" "cd \"$path\" && ls -1t" | grep -E "$pattern" | /usr/bin/head -n 20
    else
        /usr/bin/ssh "$host" "cd \"$path\" && ls -1t" | /usr/bin/head -n 20
    fi
}

progress_indicator() {
    local status_message="$1"
    local current="$2"
    local total="$3"
    local width="$4"

    # sanity defaults
    (( total > 0 ))  || total=1
    (( width > 0 ))  || width=50
    (( current >= 0 )) || current=0
    (( current > total )) && current=$total

    # compute percent + filled width
    local percent=$(( current * 100 / total ))
    local filled=$(( percent * width / 100 ))
    local percent_str="${percent}%"
    local percent_len="${#percent_str}"

    (( filled > width-percent_len-1 )) && filled=$width-percent_len-1


    local i bar_filled="" bar_empty=""

    for (( i=0; i<filled; i++ )); do bar_filled+="#"; done
    for (( i=filled; i<width-percent_len-1; i++ )); do bar_empty+="."; done

    # colors
    local c_dark_gray=$'\033[90m'
    local c_green=($(get_green_color_256 "5"))  #$'\033[32m'
    local c_light_gray=$'\033[37m'
    local c_navy=$'\033[34m'
    local c_reset=$'\033[0m'

    # build entire output in ONE variable
    local line=""
    line+="${c_light_gray}["
    line+="${c_green}${bar_filled}"
    line+="${c_light_gray}${bar_empty}"
    line+="${c_light_gray}${percent_str}] "
    line+="${c_navy}${status_message}"
    line+="${c_reset}"

    # render in place
    if [ -t 1 ]; then
        printf '\r%s' "$line"
    else
        # non-TTY fallback (no colors)
        printf '[%s%s] %s\n' "$bar_filled" "$bar_empty" "$status_message"
    fi
}


bold_put() {
    tput bold
    printf '%s' "$*"
    tput sgr0
}

bold() {
    # Print arguments in bold
    printf '\e[1m%s\e[0m' "$*"
}



# usage:
#   get_exe_path EXENAME
# returns:
#   prints full path and exit code 0 if found
#   prints nothing and exit code 1 if not found
get_exe_path() {
    local exe="$1"
    local path

    if [ -z "$exe" ]; then
        echo "usage: get_exe_path <executable>" >&2
        return 2
    fi

    # command -v works in bash, zsh, dash, etc
    path="$(command -v -- "$exe" 2>/dev/null)"

    if [ -n "$path" ]; then
        printf '%s\n' "$path"
        return 0
    fi

    # not found
    return 1
}


picker_select() {
    local prompt="$1"
    shift

    local items=()
    local line
    local count=0
    local shell_is_zsh=0

    if [ -n "$ZSH_VERSION" ] && [ -z "$BASH_VERSION" ]; then
        shell_is_zsh=1
    fi

    #fzf=$(get_exe_path ssh)
    #if [ $? -eq 0]; then
    #    echo "IN FZF"
    #    printf '%s\n' "$@" | fzf --prompt "$prompt > " --no-multi
    #    return 0
    #fi
    #echo "fzf: $fzf"

    # Collect items from arguments or stdin
    if [ "$#" -gt 0 ]; then
        items=("$@")
    else
        while IFS= read -r line; do
            [ -n "$line" ] && items+=("$line")
        done
    fi

    count=${#items[@]}

    if [ "$count" -eq 0 ]; then
        printf 'picker_select: no items to pick from\n' >&2
        return 1
    fi


    while :; do
        # prompt
        printf '%s\n\n' "$prompt" >&2

        # Print menu
        local i=1
        while [ "$i" -le "$count" ]; do
            if [ "$shell_is_zsh" -eq 1 ]; then
                # zsh arrays 1-based
                printf '  %2d) %s\n' "$i" "${items[$i]}" >&2
            else
                # bash arrays 0-based
                printf '  %2d) %s\n' "$i" "${items[$((i - 1))]}" >&2
            fi
            i=$((i + 1))
        done

        printf '\n' >&2
        printf 'Select 1-%d (0 to cancel): ' "$count" >&2

        local reply
        read -r reply || return 1

        # Empty or 0 means cancel
        if [ -z "$reply" ] || [ "$reply" = "0" ]; then
            return 1
        fi

        # Check that reply is an integer
        case "$reply" in
            *[!0-9]*)
                printf 'Invalid choice: %s\n' "$reply" >&2
                continue
                ;;
        esac

        # Range check
        if [ "$reply" -lt 1 ] || [ "$reply" -gt "$count" ]; then
            printf 'Choice out of range: %s\n' "$reply" >&2
            continue
        fi

        # Echo selected item to stdout and return success
        if [ "$shell_is_zsh" -eq 1 ]; then
            printf '%s\n' "${items[$reply]}"
        else
            printf '%s\n' "${items[$((reply - 1))]}"
        fi
        return 0
    done
}


# Simple interactive picker for zsh and bash
# Usage:
#   choice=$(picker_select "Pick a thing" "item1" "item2" "item3")
#   printf 'You chose: %s\n' "$choice"
#
# Or:
#   printf '%s\n' "one" "two" "three" | picker_select "Pick a thing"
picker_select_old() {
    local prompt="$1"
    shift

    local items=()
    local line
    local count=0
    local shell_is_zsh=0

    if [ -n "$ZSH_VERSION" ] && [ -z "$BASH_VERSION" ]; then
        shell_is_zsh=1
    fi

    # Collect items from arguments or stdin
    if [ "$#" -gt 0 ]; then
        printf "use argument\n" >&2
        items=("$@")
    else
        while IFS= read -r line; do
            printf "use stdin\n" >&2
            [ -n "$line" ] && items+=("$line")
        done
    fi

    count=${#items[@]}
    echo "\npick one of {$count} items" >&2

    if [ "$count" -eq 0 ]; then
        printf 'picker_select: no items to pick from\n' >&2
        return 1
    fi

    while :; do
        printf '%s\n' "$prompt"
        printf '\n'

        # Print menu
        local i=1
        while [ "$i" -le "$count" ]; do
            # zsh arrays are 1 based, bash arrays are 0 based
            if [ "$shell_is_zsh" -eq 1 ]; then
                printf '  %2d) %s\n' "$i" "${items[$i]}"
            else
                printf '  %2d) %s\n' "$i" "${items[$((i - 1))]}"
            fi
            i=$((i + 1))
        done

        printf '\n'
        printf 'Select 1-%d (0 to cancel): ' "$count"
        read -r reply || return 1

        # Empty or 0 means cancel
        if [ -z "$reply" ] || [ "$reply" = "0" ]; then
            return 1
        fi

        # Check that reply is an integer
        case "$reply" in
            *[!0-9]*)
                printf 'Invalid choice: %s\n' "$reply" >&2
                continue
                ;;
        esac

        # Range check
        if [ "$reply" -lt 1 ] || [ "$reply" -gt "$count" ]; then
            printf 'Choice out of range: %s\n' "$reply" >&2
            continue
        fi

        # Echo selected item and return success
        if [ "$shell_is_zsh" -eq 1 ]; then
            printf '%s\n' "${items[$reply]}"
        else
            printf '%s\n' "${items[$((reply - 1))]}"
        fi
        return 0
    done
}



#
# return the current os as an enumeration of 'linux', 'freebsd', 'maxos', 'other'
detect_os() {
    local u
    u=$(uname -s 2>/dev/null | tr '[:upper:]' '[:lower:]')

    case "$u" in
        linux)   printf 'linux';;
        freebsd) printf 'freebsd';;
        darwin)  printf 'macos';;
        *)       printf 'other';;
    esac
}


#
# count the number of files in a directory
file_count() {
    local dir_name="$1"
    count=$(find "$dir_name" -maxdepth 1 ! -name '.*' | wc -l)
    echo "$count"
}



# string_to_array take a string and return it as an array split on newlines
string_to_array() {
    local array_name="$1"
    local input="$2"
    local line

    if [ -z "$array_name" ]; then
        echo "usage: string_to_lines ARRAY_NAME STRING" >&2
        return 1
    fi

    # start with an empty array
    eval "$array_name=()"

    # read each line into the array
    while IFS= read -r line; do
        eval "$array_name+=(\"\$line\")"
    done <<EOF
$input
EOF
}



# usage:
#   string_to_lines array_var_name "$big_string"
string_to_lines() {
    local array_name="$1"
    local input="$2"
    local line

    if [ -z "$array_name" ]; then
        echo "usage: string_to_lines ARRAY_NAME STRING" >&2
        return 1
    fi

    # start with an empty array
    eval "$array_name=()"

    # read each line from the string
    while IFS= read -r line; do
        # escape backslashes and quotes for safe eval
        line=${line//\\/\\\\}
        line=${line//\"/\\\"}
        eval "$array_name+=(\"$line\")"
    done <<< "$input"
}


list_os_images() {
    # space-separated list of image extensions commonly used for OS images
    local exts="
        iso
        img
        raw
        dmg
        zip
        xz
        gz
        bz2
        7z
    "

    local patterns=""
    local e
    local files=()

    # Build patterns like *.img *.img.xz etc
    for e in $exts; do
        patterns="$patterns *.$e"
        # also catch double extensions like .img.xz, .iso.gz, etc
        patterns="$patterns *.$e.*"
    done

    # use eval to expand the patterns properly
    eval "files=($patterns)"

    # Remove non-existing matches and directories
    local out=()
    local f
    for f in "${files[@]}"; do
        [ -f "$f" ] && out+=("$f")
    done

    printf '%s\n' "${out[@]}"
}




# Usage: split_get "string" "delimiter" index
# Index is zero based: 0 = first element.
split_get() {
    local input_string="$1"
    local delimiter="$2"
    local target_index="$3"

    local current_index=0
    local token
    local rest="$input_string"

    # basic validation
    if [ -z "$delimiter" ]; then
        printf '%s' "$input_string"
        return 0
    fi

    while :; do
        case "$rest" in
            *"$delimiter"*)
                token=${rest%%"$delimiter"*}
                rest=${rest#*"$delimiter"}
                ;;
            *)
                token=$rest
                rest=
                ;;
        esac

        if [ "$current_index" -eq "$target_index" ]; then
            printf '%s' "$token"
            return 0
        fi

        [ -z "$rest" ] && break

        current_index=$((current_index + 1))
    done

    # index out of range
    return 1
}

