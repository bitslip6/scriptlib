#!/usr/bin/env bash
# generate_restore_script.sh
# Run this on a DietPi server to create a restore script
# that can be used on a fresh DietPi/Debian install.

set -euo pipefail

###############################################################################
# basic helpers
###############################################################################

log_info() {
    printf '[INFO] %s\n' "$*" >&2
}

log_warn() {
    printf '[WARN] %s\n' "$*" >&2
}

log_error() {
    printf '[ERROR] %s\n' "$*" >&2
}

ensure_root() {
    if [ "${EUID:-$(id -u)}" -ne 0 ]; then
        log_error "this script must be run as root (sudo or root shell)"
        exit 1
    fi
}

detect_package_manager() {
    if command -v apt-get >/dev/null 2>&1; then
        echo "apt-get"
        return 0
    fi

    log_error "supported package manager not found (expected apt-get)"
    exit 1
}

get_manual_packages() {
    # Use apt-mark showmanual to capture manually installed packages.
    # This avoids pulling in a huge list of base dependencies.
    if command -v apt-mark >/dev/null 2>&1; then
        apt-mark showmanual \
            | grep -v '^linux-' \
            | grep -v '^grub-' \
            | grep -v '^initramfs-tools' \
            | grep -v '^dietpi-' \
            | sort -u
    else
        # Fallback: all installed packages (less ideal, but works).
        dpkg-query -W -f='${Package}\n' | sort -u
    fi
}

make_output_filename() {
    local hostname_str date_str
    hostname_str="$(hostname 2>/dev/null || echo 'unknownhost')"
    date_str="$(date +%Y%m%d_%H%M%S)"
    printf 'restore_%s_%s.sh\n' "$hostname_str" "$date_str"
}

###############################################################################
# main generator
###############################################################################

main() {
    ensure_root

    local pkg_mgr
    pkg_mgr="$(detect_package_manager)"

    log_info "detected package manager: ${pkg_mgr}"

    local output_script
    output_script="$(make_output_filename)"

    log_info "collecting manually installed packages"
    mapfile -t packages < <(get_manual_packages)

    if [ "${#packages[@]}" -eq 0 ]; then
        log_warn "no packages detected, nothing to write"
        exit 0
    fi

    log_info "generating restore script: ${output_script}"

    umask 077

    ###########################################################################
    # write header of restore script
    ###########################################################################
    cat >"${output_script}" <<'EOF_HEADER'
#!/usr/bin/env bash
# Generated restore script for DietPi / Debian based system.
# This script installs the recorded package set from the source server.
#
# Notes:
#   * It does NOT copy configuration files or host keys.
#   * Package installation is done in a way that preserves existing config
#     files on the new system.
#
# Requirements:
#   * Run as root or via sudo.
#   * Network access to your package repositories.

set -euo pipefail

###############################################################################
# basic helpers
###############################################################################

log_info() {
    printf '[INFO] %s\n' "$*" >&2
}

log_warn() {
    printf '[WARN] %s\n' "$*" >&2
}

log_error() {
    printf '[ERROR] %s\n' "$*" >&2
}

ensure_root() {
    if [ "${EUID:-$(id -u)}" -ne 0 ]; then
        log_error "this script must be run as root (sudo or root shell)"
        exit 1
    fi
}

detect_package_manager() {
    if command -v apt-get >/dev/null 2>&1; then
        echo "apt-get"
        return 0
    fi

    log_error "supported package manager not found (expected apt-get)"
    exit 1
}

# wrapper for running commands with logging
run_cmd() {
    log_info "running: $*"
    "$@"
}

###############################################################################
# progress and picker placeholders
###############################################################################
# You mentioned you already have:
#   progress(current_iter, max_iter, bar_width)
#   picker(array_of_choices)
#
# The calls below are commented out placeholders showing where you might use
# these helpers.

# progress_placeholder() {
#     local current="$1"
#     local total="$2"
#     local width="$3"
#     # Uncomment the next line when your progress() function is available:
#     # progress "$current" "$total" "$width"
# }

# picker_placeholder() {
#     # Example of using picker with an array of choices:
#     # local choices=( "${packages[@]}" )
#     # local selection
#     # selection="$(picker "${choices[@]}")"
#     # echo "you picked: $selection"
#     :
# }

###############################################################################
# package list captured from source server
###############################################################################

packages=(
EOF_HEADER

    ###########################################################################
    # append package list
    ###########################################################################
    local pkg
    for pkg in "${packages[@]}"; do
        # Debian package names are simple, no need for heavy escaping
        printf "    '%s'\n" "$pkg" >>"${output_script}"
    done

    ###########################################################################
    # write footer of restore script
    ###########################################################################
    cat >>"${output_script}" <<'EOF_FOOTER'
)

###############################################################################
# install logic
###############################################################################

install_packages() {
    ensure_root

    local pkg_mgr
    pkg_mgr="$(detect_package_manager)"

    # preserve existing config files while installing
    export DEBIAN_FRONTEND=noninteractive

    run_cmd "$pkg_mgr" update

    local total count pkg
    total="${#packages[@]}"
    count=0

    log_info "about to install ${total} packages"

    for pkg in "${packages[@]}"; do
        count=$((count + 1))
        log_info "[${count}/${total}] installing package: ${pkg}"

        # Progress bar placeholder. Uncomment when progress() is available.
        # progress "$count" "$total" 40

        # Install package, keep existing config files if present.
        run_cmd "$pkg_mgr" install -y \
            -o Dpkg::Options::=--force-confdef \
            -o Dpkg::Options::=--force-confold \
            "$pkg" || log_warn "failed to install package: ${pkg}"
    done

    log_info "package installation completed"
}

###############################################################################
# optional utility: dry run printer
###############################################################################

print_package_list() {
    local pkg
    for pkg in "${packages[@]}"; do
        echo "$pkg"
    done
}

###############################################################################
# entry point
###############################################################################

main() {
    log_info "starting restore script"
    install_packages
    log_info "restore script completed"
}

main "$@"
EOF_FOOTER

    chmod +x "${output_script}"
    log_info "restore script written to ${output_script}"
    log_info "copy this script to your new DietPi server and run it as root"
    log_info "it will preserve existing config files and host keys"
}

main "$@"

