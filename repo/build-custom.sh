#!/usr/bin/env bash
set -euo pipefail

readonly REPO_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
readonly PROJECT_DIR="$(cd -- "$REPO_DIR/.." && pwd -P)"
readonly OUT_DIR="${1:-$REPO_DIR/out}"
readonly LOCKED_COMMIT="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["upstreams"]["kage-shell"]["revision"])' "$PROJECT_DIR/upstreams.lock.json")"
readonly PACKAGED_COMMIT="$(sed -n 's/^_commit=//p' "$REPO_DIR/glyph-shell/PKGBUILD")"

command -v makepkg >/dev/null 2>&1 || { printf 'makepkg is required\n' >&2; exit 1; }
command -v repo-add >/dev/null 2>&1 || { printf 'repo-add is required\n' >&2; exit 1; }
[[ "$LOCKED_COMMIT" == "$PACKAGED_COMMIT" ]] || {
    printf 'Kage PKGBUILD commit does not match upstreams.lock.json\n' >&2
    exit 1
}

install -d -m 0755 "$OUT_DIR"
(
    cd "$REPO_DIR/glyph-shell"
    makepkg --cleanbuild --clean --noconfirm --force
)
install -m 0644 "$REPO_DIR/glyph-shell"/*.pkg.tar.zst "$OUT_DIR/"

packages=("$OUT_DIR"/*.pkg.tar.zst)
if [[ -n ${GLYPH_REPO_SIGNING_KEY:-} ]]; then
    repo-add -s -k "$GLYPH_REPO_SIGNING_KEY" "$OUT_DIR/arca.db.tar.zst" "${packages[@]}"
else
    repo-add "$OUT_DIR/arca.db.tar.zst" "${packages[@]}"
fi

printf 'Custom Zenith packages written to %s\n' "$OUT_DIR"
