#!/usr/bin/env bash
set -euo pipefail

readonly PROJECT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
errors=0

fail() {
    printf 'FAIL: %s\n' "$*" >&2
    errors=$((errors + 1))
}

find_source_scripts() {
    find "$PROJECT_DIR" \
        \( -path "$PROJECT_DIR/.local-tools" -o -path "$PROJECT_DIR/work" -o -path "$PROJECT_DIR/out" -o -path "$PROJECT_DIR/out-fixed" -o -path "$PROJECT_DIR/repo/out" \) -prune -o \
        -type f \( -name '*.sh' -o -path '*/usr/local/bin/*' -o -path '*/usr/local/lib/glyph/*' \) -print
}

printf 'Checking shell syntax...\n'
while IFS= read -r script; do
    bash -n "$script" || fail "Bash syntax: $script"
done < <(find_source_scripts)

if command -v fish >/dev/null 2>&1; then
    while IFS= read -r config; do
        fish -n "$config" || fail "Fish syntax: $config"
    done < <(find "$PROJECT_DIR/overlay" -type f -name '*.fish' -print)
fi

printf 'Checking package manifests...\n'
manifest_words="$(mktemp)"
available_words="$(mktemp)"
trap 'rm -f -- "$manifest_words" "$available_words"' EXIT
awk '!/^[[:space:]]*(#|$)/ {print $1}' "$PROJECT_DIR"/packages/*.x86_64 >"$manifest_words"

duplicates="$(LC_ALL=C sort "$manifest_words" | uniq -d)"
[[ -z "$duplicates" ]] || fail "duplicate packages across manifests: ${duplicates//$'\n'/, }"

if command -v pacman >/dev/null 2>&1; then
    pacman -Slq core extra 2>/dev/null | LC_ALL=C sort -u >"$available_words"
    while IFS= read -r package; do
        fail "package unavailable in configured repositories: $package"
    done < <(comm -23 <(LC_ALL=C sort -u "$manifest_words") "$available_words")
else
    printf 'SKIP: package availability (pacman not installed)\n'
fi

printf 'Checking project invariants...\n'
for required in \
    overlay/usr/local/bin/glyph \
    overlay/usr/local/bin/glyph-control \
    overlay/usr/local/bin/glyph-pkg \
    overlay/usr/local/bin/glyph-cap \
    overlay/usr/local/bin/tac \
    overlay/usr/local/bin/glyph-open \
    overlay/usr/local/bin/glyph-install \
    overlay/usr/local/bin/glyph-deploy \
    overlay/usr/local/bin/glyph-doctor \
    overlay/root/.zprofile \
    overlay/etc/skel/.config/fish/config.fish \
    overlay/etc/glyph/apps.tsv \
    overlay/etc/glyph/capabilities.tsv \
    docs/LINUXLINKS_TUI_100.md \
    repo/build-meta.sh; do
    [[ -f "$PROJECT_DIR/$required" ]] || fail "missing $required"
done

capability_db="$PROJECT_DIR/overlay/etc/glyph/capabilities.tsv"
duplicate_aliases="$(awk -F '\t' '$0 !~ /^#/ {print $1}' "$capability_db" | LC_ALL=C sort | uniq -d)"
[[ -z "$duplicate_aliases" ]] || fail "duplicate capability aliases: ${duplicate_aliases//$'\n'/, }"

while IFS=$'\t' read -r alias role provider command_name description; do
    [[ -n "$alias" && "$alias" != \#* ]] || continue
    [[ "$alias" =~ ^[a-z0-9][a-z0-9-]*$ ]] || fail "invalid capability alias: $alias"
    [[ -n "$role" && -n "$provider" && -n "$command_name" && -n "$description" ]] || \
        fail "incomplete capability row: $alias"
done <"$capability_db"

if command -v shellcheck >/dev/null 2>&1; then
    mapfile -t bash_scripts < <(find_source_scripts)
    shellcheck -x "${bash_scripts[@]}" || fail "ShellCheck"
else
    printf 'SKIP: ShellCheck (not installed)\n'
fi

if ((errors)); then
    printf '%d check(s) failed.\n' "$errors" >&2
    exit 1
fi
printf 'All checks passed.\n'
