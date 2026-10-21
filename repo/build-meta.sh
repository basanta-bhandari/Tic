#!/usr/bin/env bash
set -euo pipefail

readonly REPO_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
readonly PROJECT_DIR="$(cd -- "$REPO_DIR/.." && pwd -P)"
readonly CAP_DB="$PROJECT_DIR/overlay/etc/glyph/capabilities.tsv"
readonly OUT_DIR="${1:-$REPO_DIR/out}"

command -v makepkg >/dev/null 2>&1 || { printf 'makepkg is required\n' >&2; exit 1; }
command -v repo-add >/dev/null 2>&1 || { printf 'repo-add is required\n' >&2; exit 1; }
[[ -r "$CAP_DB" ]] || { printf 'missing %s\n' "$CAP_DB" >&2; exit 1; }

stage="$(mktemp -d -t glyph-meta.XXXXXX)"
trap 'rm -rf -- "$stage"' EXIT
install -d -m 0755 "$OUT_DIR"

while IFS=$'\t' read -r alias role provider command_name description; do
    [[ -n "$alias" && "$alias" != \#* ]] || continue
    [[ "$alias" =~ ^[a-z0-9][a-z0-9-]*$ ]] || { printf 'invalid alias: %s\n' "$alias" >&2; exit 1; }
    [[ "$provider" =~ ^[a-zA-Z0-9@._+-]+$ ]] || { printf 'invalid provider: %s\n' "$provider" >&2; exit 1; }

    pkgdir="$stage/$alias"
    install -d -m 0755 "$pkgdir"
    escaped_description="${description//\'/\'\\\'\'}"
    printf '%s\n' \
        "pkgname=$alias" \
        'pkgver=1.0' \
        'pkgrel=1' \
        "pkgdesc='$escaped_description (Glyph capability: $role)'" \
        "arch=('any')" \
        "url='https://example.invalid/glyph-linux'" \
        "license=('MIT')" \
        "depends=('$provider')" \
        "_glyph_command='$command_name'" \
        'package() {' \
        '  install -Dm644 /dev/null "$pkgdir/usr/share/glyph/capabilities/$pkgname"' \
        '  printf "%s\n" "provider=${depends[0]}" "command=$_glyph_command" >"$pkgdir/usr/share/glyph/capabilities/$pkgname"' \
        '}' \
        >"$pkgdir/PKGBUILD"

    (
        cd "$pkgdir"
        makepkg --cleanbuild --nodeps --noconfirm --force
    )
    install -m 0644 "$pkgdir"/*.pkg.tar.zst "$OUT_DIR/"
done <"$CAP_DB"

packages=("$OUT_DIR"/*.pkg.tar.zst)
if [[ -n ${GLYPH_REPO_SIGNING_KEY:-} ]]; then
    repo-add -s -k "$GLYPH_REPO_SIGNING_KEY" "$OUT_DIR/tic.db.tar.zst" "${packages[@]}"
else
    repo-add "$OUT_DIR/tic.db.tar.zst" "${packages[@]}"
fi

printf 'Tic repository written to %s\n' "$OUT_DIR"
