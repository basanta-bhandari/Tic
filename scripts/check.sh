#!/usr/bin/env bash
set -euo pipefail

readonly PROJECT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
errors=0

fail() {
    printf 'FAIL: %s\n' "$*" >&2
    errors=$((errors + 1))
}

find_script_candidates() {
    find "$PROJECT_DIR" \
        \( -path "$PROJECT_DIR/.local-tools" -o -path "$PROJECT_DIR/work" -o -path "$PROJECT_DIR/work-*" -o -path "$PROJECT_DIR/out" -o -path "$PROJECT_DIR/out-*" -o -path "$PROJECT_DIR/repo/out" \) -prune -o \
        -type f \( -name '*.sh' -o -path '*/usr/local/bin/*' -o -path '*/usr/local/lib/glyph/*' \) -print
}

find_bash_scripts() {
    local candidate
    while IFS= read -r candidate; do
        if head -n 1 "$candidate" | grep -Eq '^#!.*(/|env )(ba)?sh([[:space:]]|$)'; then
            printf '%s\n' "$candidate"
        fi
    done < <(find_script_candidates)
}

printf 'Checking shell syntax...\n'
while IFS= read -r script; do
    bash -n "$script" || fail "Bash syntax: $script"
done < <(find_bash_scripts)

if command -v python3 >/dev/null 2>&1; then
    python_cache="$(mktemp -d -t glyph-python.XXXXXX)"
    while IFS= read -r script; do
        if head -n 1 "$script" | grep -Eq '^#!.*python3?([[:space:]]|$)'; then
            PYTHONPYCACHEPREFIX="$python_cache" python3 -m py_compile "$script" || \
                fail "Python syntax: $script"
        fi
    done < <(find_script_candidates)
    rm -rf -- "$python_cache"
fi

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
    done < <(comm -23 <(LC_ALL=C sort -u "$manifest_words") "$available_words" | grep -v '^archcraft-' | grep -v '^kage-shell$' || true)
else
    printf 'SKIP: package availability (pacman not installed)\n'
fi

printf 'Checking project invariants...\n'
for required in \
    overlay/usr/local/bin/glyph \
    overlay/usr/local/bin/glyph-control \
    overlay/usr/local/bin/glyph-pkg \
    overlay/usr/local/bin/glyph-cap \
    overlay/usr/local/bin/arca \
    overlay/usr/local/bin/zenith \
    overlay/usr/local/bin/imperium \
    overlay/usr/local/bin/glyph-open \
    overlay/usr/local/bin/glyph-install \
    overlay/usr/local/bin/glyph-deploy \
    overlay/usr/local/bin/glyph-doctor \
    overlay/usr/local/bin/glyph-overview \
    overlay/usr/local/bin/glyph-session \
    overlay/usr/local/bin/glyph-kitty \
    overlay/usr/local/bin/glyph-mux \
    overlay/usr/local/bin/glyph-theme \
    overlay/usr/local/bin/glyph-wallpaper \
    overlay/usr/local/bin/glyph-store \
    overlay/root/.zprofile \
    overlay/etc/skel/.config/fish/config.fish \
    overlay/etc/glyph/apps.tsv \
    overlay/etc/glyph/capabilities.tsv \
    overlay/etc/glyph/sway.conf \
    overlay/etc/glyph/kitty.conf \
    overlay/etc/glyph/themes.tsv \
    overlay/etc/glyph/tui-catalog.tsv \
    packages/archcraft-base.x86_64 \
    packages/session.x86_64 \
    overlay/usr/share/wayland-sessions/glyph.desktop \
    docs/COSMIC_SHORTCUTS.md \
    docs/PERFORMANCE_AUDIT.md \
    docs/ESSENTIALS.md \
    docs/LINUXLINKS_TUI_100.md \
    scripts/fetch-archcraft-profile.sh \
    repo/build-meta.sh \
    repo/build-custom.sh \
    repo/glyph-shell/PKGBUILD \
    upstreams.lock.json; do
    [[ -f "$PROJECT_DIR/$required" ]] || fail "missing $required"
done

tui_catalog="$PROJECT_DIR/overlay/etc/glyph/tui-catalog.tsv"
tui_count="$(awk -F '\t' '$0 !~ /^#/ {count++} END {print count+0}' "$tui_catalog")"
[[ "$tui_count" == 100 ]] || fail "TUI catalog must contain 100 entries, found $tui_count"
duplicate_ranks="$(awk -F '\t' '$0 !~ /^#/ {print $1}' "$tui_catalog" | LC_ALL=C sort | uniq -d)"
[[ -z "$duplicate_ranks" ]] || fail "duplicate TUI catalog ranks: ${duplicate_ranks//$'\n'/, }"

capability_db="$PROJECT_DIR/overlay/etc/glyph/capabilities.tsv"
duplicate_aliases="$(awk -F '\t' '$0 !~ /^#/ {print $1}' "$capability_db" | LC_ALL=C sort | uniq -d)"
[[ -z "$duplicate_aliases" ]] || fail "duplicate capability aliases: ${duplicate_aliases//$'\n'/, }"

while IFS=$'\t' read -r alias role provider command_name description; do
    [[ -n "$alias" && "$alias" != \#* ]] || continue
    [[ "$alias" =~ ^[a-z0-9][a-z0-9-]*$ ]] || fail "invalid capability alias: $alias"
    [[ -n "$role" && -n "$provider" && -n "$command_name" && -n "$description" ]] || \
        fail "incomplete capability row: $alias"
done <"$capability_db"

locked_shell_commit="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["upstreams"]["kage-shell"]["revision"])' "$PROJECT_DIR/upstreams.lock.json")"
packaged_shell_commit="$(sed -n 's/^_commit=//p' "$PROJECT_DIR/repo/glyph-shell/PKGBUILD")"
[[ "$locked_shell_commit" == "$packaged_shell_commit" ]] || \
    fail "Kage PKGBUILD is not pinned to upstreams.lock.json"

home_snapshot="$(GLYPH_APP_DB="$PROJECT_DIR/overlay/etc/glyph/apps.tsv" \
    "$PROJECT_DIR/overlay/usr/local/bin/glyph" --snapshot 100x30)"
grep -q 'CONNECTIONS' <<<"$home_snapshot" || fail "Zenith Home snapshot has no connections panel"
grep -q 'QUICK LAUNCH' <<<"$home_snapshot" || fail "Zenith Home snapshot has no quick-launch panel"
grep -q 'ZENITH' <<<"$home_snapshot" || fail "Zenith Home snapshot has no Zenith identity"

if command -v shellcheck >/dev/null 2>&1; then
    mapfile -t bash_scripts < <(find_bash_scripts)
    shellcheck -x "${bash_scripts[@]}" || fail "ShellCheck"
else
    printf 'SKIP: ShellCheck (not installed)\n'
fi

if ((errors)); then
    printf '%d check(s) failed.\n' "$errors" >&2
    exit 1
fi
printf 'All checks passed.\n'
