#!/usr/bin/env bash
set -euo pipefail

readonly PROJECT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
readonly BUILD_DIR="$PROJECT_DIR/work"

if [[ ! -e "$BUILD_DIR" ]]; then
    printf 'Nothing to clean.\n'
    exit 0
fi

if findmnt -rn -R --mountpoint "$BUILD_DIR" 2>/dev/null | grep -q .; then
    printf 'Refusing to clean %s because it contains a mount.\n' "$BUILD_DIR" >&2
    exit 1
fi

case "$BUILD_DIR" in
    "$PROJECT_DIR"/work) rm -rf --one-file-system -- "$BUILD_DIR" ;;
    *) printf 'Refusing unexpected path: %s\n' "$BUILD_DIR" >&2; exit 1 ;;
esac
printf 'Removed %s\n' "$BUILD_DIR"
