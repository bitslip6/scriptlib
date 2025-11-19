
progress_indicator() {
    local status_message="$1"
    local current="$2"
    local total="$3"
    local width="$4"

    echo "current [$current]"
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
    local c_green=$'\033[32m'
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


progress_indicator_3() {
    local status_message="$1"
    local current="$2"
    local total="$3"
    local width="$4"

    # sanity defaults
    if ! [ "$total" -gt 0 ] 2>/dev/null; then
        total=1
    fi
    if ! [ "$width" -gt 0 ] 2>/dev/null; then
        width=50
    fi
    if ! [ "$current" -ge 0 ] 2>/dev/null; then
        current=0
    fi
    if [ "$current" -gt "$total" ] 2>/dev/null; then
        current="$total"
    fi

    # percentage and filled width
    local percent filled
    percent=$(( current * 100 / total ))
    filled=$(( percent * width / 100 ))
    if [ "$filled" -gt "$width" ]; then
        filled="$width"
    fi

    # build bars
    local i
    local bar_filled=""
    local bar_empty=""

    for (( i = 0; i < filled; i++ )); do
        bar_filled="${bar_filled}#"
    done
    for (( i = filled; i < width; i++ )); do
        bar_empty="${bar_empty}."
    done

    # colors using ANSI C quoting (bash/zsh)
    local color_dark_gray=$'\033[90m'
    local color_green=$'\033[32m'
    local color_light_gray=$'\033[37m'
    local color_navy=$'\033[34m'
    local color_reset=$'\033[0m'

    # if stdout is not a TTY, skip colors and \r
    if ! [ -t 1 ]; then
        printf '[%s%s] %s\n' "$bar_filled" "$bar_empty" "$status_message"
        return 0
    fi

    # render in place (no newline)
    printf '\r%s[%s %s%s%s]%s %s%s%s' \
        "$color_dark_gray" \
        "$color_green" "$bar_filled" \
        "$color_light_gray" "$bar_empty" \
        "$color_dark_gray" \
        "$color_navy" "$status_message" "$color_reset"
}


progress_indicator_old() {
    local status_message="$1"
    local current="$2"
    local total="$3"
    local width="$4"

    # debug flag: set PROGRESS_DEBUG=1 in env to see messages
    if [ "$PROGRESS_DEBUG" = "1" ]; then
        printf 'DEBUG: progress_indicator called with:\n' >&2
        printf '  status_message="%s"\n' "$status_message" >&2
        printf '  current="%s"\n' "$current" >&2
        printf '  total="%s"\n' "$total" >&2
        printf '  width="%s"\n' "$width" >&2
    fi

    # sanity defaults
    if ! [ "$total" -gt 0 ] 2>/dev/null; then
        [ "$PROGRESS_DEBUG" = "1" ] && printf 'DEBUG: invalid total "%s", forcing to 1\n' "$total" >&2
        total=1
    fi

    if ! [ "$width" -gt 0 ] 2>/dev/null; then
        [ "$PROGRESS_DEBUG" = "1" ] && printf 'DEBUG: invalid width "%s", forcing to 50\n' "$width" >&2
        width=50
    fi

    if ! [ "$current" -ge 0 ] 2>/dev/null; then
        [ "$PROGRESS_DEBUG" = "1" ] && printf 'DEBUG: invalid current "%s", forcing to 0\n' "$current" >&2
        current=0
    fi

    if [ "$current" -gt "$total" ] 2>/dev/null; then
        [ "$PROGRESS_DEBUG" = "1" ] && printf 'DEBUG: current > total, clamping\n' >&2
        current="$total"
    fi

    # percentage and filled width
    local percent filled
    percent=$(( current * 100 / total ))
    filled=$(( percent * width / 100 ))
    if [ "$filled" -gt "$width" ]; then
        [ "$PROGRESS_DEBUG" = "1" ] && printf 'DEBUG: filled > width, clamping\n' >&2
        filled="$width"
    fi

    [ "$PROGRESS_DEBUG" = "1" ] && {
        printf 'DEBUG: percent=%s\n' "$percent" >&2
        printf 'DEBUG: filled=%s\n' "$filled" >&2
    }

    # build bars
    local i
    local bar_filled=""
    local bar_empty=""

    for (( i = 0; i < filled; i++ )); do
        bar_filled="${bar_filled}#"
    done
    for (( i = filled; i < width; i++ )); do
        bar_empty="${bar_empty}."
    done

    [ "$PROGRESS_DEBUG" = "1" ] && {
        printf 'DEBUG: bar_filled="%s"\n' "$bar_filled" >&2
        printf 'DEBUG: bar_empty ="%s"\n' "$bar_empty" >&2
    }

    # colors
    local color_dark_gray="\033[90m"
    local color_green="\033[32m"
    local color_light_gray="\033[37m"
    local color_navy="\033[34m"
    local color_reset="\033[0m"

    # if stdout is not a tty, just print a plain line for debugging
    if ! [ -t 1 ]; then
        [ "$PROGRESS_DEBUG" = "1" ] && printf 'DEBUG: stdout is not a TTY, printing plain line\n' >&2
        printf '[%s%s] %s\n' "$bar_filled" "$bar_empty" "$status_message"
        return 0
    fi

    [ "$PROGRESS_DEBUG" = "1" ] && printf 'DEBUG: printing colored line with \\r\n' >&2

    # render in place (no newline)
    printf '\r%s[%s%s%s%s]%s %s%s%s' \
        "$color_dark_gray" \
        "$color_green" "$bar_filled" \
        "$color_light_gray" "$bar_empty" \
        "$color_dark_gray" \
        "$color_navy" "$status_message" "$color_reset"
}

