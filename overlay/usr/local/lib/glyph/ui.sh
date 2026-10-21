#!/usr/bin/env bash

export DIALOGRC="${DIALOGRC:-/etc/glyph/dialogrc}"
export LESS="${LESS:--RF}"

glyph_dialog() {
    dialog --stdout --colors --backtitle " GLYPH LINUX // TEXT WORKSTATION " "$@"
}

glyph_message() {
    glyph_dialog --title "${1:-Glyph}" --msgbox "${2:-}" 10 68
}

glyph_confirm() {
    glyph_dialog --title "${1:-Confirm}" --yesno "${2:-Continue?}" 10 68
}

glyph_pause() {
    printf '\n\033[33mPress Enter to return to Glyph...\033[0m'
    read -r _
}

glyph_run() {
    clear
    "$@"
    local status=$?
    if ((status != 0)); then
        printf '\n\033[1;31mCommand exited with status %d.\033[0m\n' "$status" >&2
    fi
    glyph_pause
    return 0
}

glyph_as_root() {
    if ((EUID == 0)); then
        "$@"
    elif command -v sudo >/dev/null 2>&1; then
        sudo -- "$@"
    else
        printf 'Administrator privileges are required.\n' >&2
        return 1
    fi
}

glyph_require() {
    command -v "$1" >/dev/null 2>&1 && return 0
    glyph_message "Missing application" "The command '$1' is not installed.\n\nInstall it with:\n  sudo pacman -S $1"
    return 1
}

glyph_cleanup_terminal() {
    stty sane 2>/dev/null || true
    tput cnorm 2>/dev/null || true
    clear 2>/dev/null || true
}
