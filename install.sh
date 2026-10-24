#!/usr/bin/env bash
set -Eeuo pipefail

readonly RUNE_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
if [[ -d "$RUNE_DIR/.git" && -f "$RUNE_DIR/build.sh" ]]; then
    default_project_dir="$RUNE_DIR"
else
    default_project_dir="$RUNE_DIR/Arca"
fi
readonly PROJECT_DIR="${RUNE_PROJECT_DIR:-$default_project_dir}"
readonly PROJECT_URL="${RUNE_PROJECT_URL:-git@github.com:basanta-bhandari/Tic.git}"
readonly DEPENDENCY_FILE="$RUNE_DIR/dependencies.txt"

build=true
if [[ "${1:-}" == "--no-build" ]]; then
    build=false
elif [[ -n "${1:-}" ]]; then
    printf 'Usage: %s [--no-build]\n' "$0" >&2
    exit 2
fi

if ! command -v pacman >/dev/null 2>&1; then
    printf 'Rune currently supports Arch Linux hosts (pacman was not found).\n' >&2
    exit 1
fi

mapfile -t dependencies < <(sed -E '/^[[:space:]]*(#|$)/d; s/[[:space:]]+#.*$//' "$DEPENDENCY_FILE")
printf 'Installing Zenith build and QEMU dependencies...\n'
sudo pacman -S --needed --noconfirm "${dependencies[@]}"

if [[ -d "$PROJECT_DIR/.git" ]]; then
    printf 'Updating %s...\n' "$PROJECT_DIR"
    git -C "$PROJECT_DIR" pull --ff-only
elif [[ -e "$PROJECT_DIR" ]]; then
    printf '%s exists but is not a Git checkout; refusing to overwrite it.\n' "$PROJECT_DIR" >&2
    exit 1
else
    printf 'Cloning Arca into %s...\n' "$PROJECT_DIR"
    git clone "$PROJECT_URL" "$PROJECT_DIR"
fi

make -C "$PROJECT_DIR" check

if $build; then
    printf 'Building pinned custom runtime packages...\n'
    make -C "$PROJECT_DIR" custom-packages
    printf 'Fetching the pinned Archcraft profile...\n'
    "$PROJECT_DIR/scripts/fetch-archcraft-profile.sh" >/dev/null
    printf 'Building the Zenith OS ISO; this may take a while...\n'
    sudo --preserve-env=PATH,ARCHCRAFT_REF make -C "$PROJECT_DIR" iso
else
    printf 'Setup complete. Build later with: sudo make -C %q iso\n' "$PROJECT_DIR"
fi

printf '\nRune is ready. Start Zenith with:\n  %q\n' "$RUNE_DIR/run.sh"
