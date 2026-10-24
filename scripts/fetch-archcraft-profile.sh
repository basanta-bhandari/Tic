#!/usr/bin/env bash
set -euo pipefail

readonly PROJECT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
readonly REPOSITORY="${ARCHCRAFT_REPOSITORY:-https://github.com/archcraft-os/archcraft.git}"
readonly REF="${ARCHCRAFT_REF:-310a3cb83f20a70569c6ad0621e6d200f08fd6f3}"
readonly CHECKOUT="$PROJECT_DIR/work/upstream/archcraft"

if [[ ! -d "$CHECKOUT/.git" ]]; then
    printf 'Fetching Archcraft ISO profile...\n' >&2
    install -d -m 0755 "$(dirname -- "$CHECKOUT")"
    git clone --filter=blob:none --no-checkout "$REPOSITORY" "$CHECKOUT" >&2
fi

if ! git -C "$CHECKOUT" cat-file -e "$REF^{commit}" 2>/dev/null; then
    git -C "$CHECKOUT" fetch --depth 1 origin "$REF" >&2
fi
git -C "$CHECKOUT" checkout --detach --force "$REF" >&2

[[ -r "$CHECKOUT/profile/profiledef.sh" ]] || {
    printf 'fetch-archcraft-profile: upstream profile is incomplete\n' >&2
    exit 1
}
printf '%s\n' "$CHECKOUT/profile"
