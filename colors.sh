#!/usr/bin/env zsh
get_yellow_color_256() {
    local level="$1" code
    [ "$level" -lt 1 ] && level=1
    [ "$level" -gt 10 ] && level=10

    case "$level" in
        1|2)  code=58  ;;  # dark yellow / brownish
        3|4)  code=100 ;;
        5|6)  code=142 ;;
        7|8)  code=148 ;;
        9)    code=184 ;;
        10)   code=190 ;;
    esac

    printf '\033[38;5;%sm' "$code"
}

get_purple_color_256() {
    local level="$1" code
    [ "$level" -lt 1 ] && level=1
    [ "$level" -gt 10 ] && level=10

    case "$level" in
        1|2)  code=53  ;;  # darkest purple
        3|4)  code=90  ;;
        5|6)  code=127 ;;
        7|8)  code=163 ;;
        9)    code=165 ;;
        10)   code=13  ;;  # system fuchsia
    esac

    printf '\033[38;5;%sm' "$code"
}

get_blue_color_256() {
    local level="$1" code
    [ "$level" -lt 1 ] && level=1
    [ "$level" -gt 10 ] && level=10

    case "$level" in
        1|2)  code=17  ;;  # darkest blue
        3|4)  code=18  ;;
        5|6)  code=19  ;;
        7|8)  code=20  ;;
        9)    code=21  ;;
        10)   code=12  ;;  # system blue
    esac

    printf '\033[38;5;%sm' "$code"
}

get_green_color_256() {
    local level="$1" code
    [ "$level" -lt 1 ] && level=1
    [ "$level" -gt 10 ] && level=10

    case "$level" in
        1|2)  code=22  ;;  # darkest green
        3|4)  code=28  ;;
        5|6)  code=34  ;;
        7|8)  code=40  ;;
        9)    code=46  ;;
        10)   code=10  ;;  # system lime
    esac

    printf '\033[38;5;%sm' "$code"
}

get_red_color_256() {
    local level="$1" code
    # clamp 1–10
    [ "$level" -lt 1 ] && level=1
    [ "$level" -gt 10 ] && level=10

    case "$level" in
        1|2)  code=52  ;;  # darkest red
        3|4)  code=88  ;;
        5|6)  code=124 ;;
        7|8)  code=160 ;;
        9)    code=196 ;;
        10)   code=9   ;;  # system bright red
    esac

    printf '\033[38;5;%sm' "$code"
}


get_grey_color_256() {
    local level="$1" code
    [ "$level" -lt 1 ] && level=1
    [ "$level" -gt 10 ] && level=10

    case "$level" in
        1|2)  code=232 ;;  # darkest grey
        3|4)  code=236 ;;
        5|6)  code=240 ;;
        7|8)  code=244 ;;
        9)    code=248 ;;
        10)   code=252 ;;
    esac

    printf '\033[38;5;%sm' "$code"
}

