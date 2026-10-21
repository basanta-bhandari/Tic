#!/usr/bin/env bash
set -euo pipefail

readonly PROJECT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"

flavor="full"
archiso_profile="${ARCHISO_PROFILE:-/usr/share/archiso/configs/releng}"
profile_only=0

usage() {
    cat <<'EOF'
Usage: ./build.sh [OPTIONS]

Build a Glyph Linux Archiso image.

Options:
  --flavor core|full|dev    Package set to include (default: full)
  --archiso-profile PATH   Releng profile to derive from
  --profile-only           Prepare work/profile but do not invoke mkarchiso
  -h, --help               Show this help

Environment:
  OUT_DIR                  ISO destination (default: PROJECT/out)
  PACMAN_CACHE_DIR         Writable package cache override for Archiso
  PACMAN_DOWNLOAD_USER     Pacman download user override (e.g. root in userns)
EOF
}

die() {
    printf 'glyph-build: %s\n' "$*" >&2
    exit 1
}

safe_remove_tree() {
    local target="$1"
    case "$target" in
        "$PROJECT_DIR"/work/*) ;;
        *) die "refusing to clear unexpected path: $target" ;;
    esac

    if findmnt -rn -R --mountpoint "$target" 2>/dev/null | grep -q .; then
        die "refusing to clear $target because it contains a mount"
    fi
    rm -rf --one-file-system -- "$target"
}

while (($#)); do
    case "$1" in
        --flavor)
            (($# >= 2)) || die "--flavor requires a value"
            flavor="$2"
            shift 2
            ;;
        --archiso-profile)
            (($# >= 2)) || die "--archiso-profile requires a path"
            archiso_profile="$2"
            shift 2
            ;;
        --profile-only)
            profile_only=1
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            die "unknown option: $1"
            ;;
    esac
done

case "$flavor" in
    core|full|dev) ;;
    *) die "flavor must be core, full, or dev" ;;
esac

[[ -r "$archiso_profile/profiledef.sh" ]] || die "no Archiso profile at $archiso_profile"
[[ -r "$archiso_profile/packages.x86_64" ]] || die "profile has no packages.x86_64"

readonly WORK_DIR="${WORK_DIR:-$PROJECT_DIR/work}"
readonly OUT_DIR="${OUT_DIR:-$PROJECT_DIR/out}"
readonly PROFILE_DIR="$WORK_DIR/profile"
readonly MKARCHISO_WORK="$WORK_DIR/mkarchiso"

case "$WORK_DIR" in
    "$PROJECT_DIR"/work) ;;
    *) die "WORK_DIR must resolve to $PROJECT_DIR/work for safe cleanup" ;;
esac

"$PROJECT_DIR/scripts/check.sh"

if [[ -e "$PROFILE_DIR" ]]; then
    safe_remove_tree "$PROFILE_DIR"
fi
install -d -m 0755 "$WORK_DIR" "$OUT_DIR"
cp -a -- "$archiso_profile" "$PROFILE_DIR"
cp -a -- "$PROJECT_DIR/overlay/." "$PROFILE_DIR/airootfs/"
# Archiso's live root account already exists, so its customization pass does
# not populate it from /etc/skel. Seed missing dotfiles explicitly while
# retaining root-only overrides such as .zprofile and the Fish shim.
cp -a -n -- "$PROFILE_DIR/airootfs/etc/skel/." "$PROFILE_DIR/airootfs/root/"
# Releng uses zsh for the live root account and has historically enabled
# systemd-networkd's socket. Glyph enters Fish from root's zprofile and gives
# NetworkManager exclusive ownership of networking.
ln -sfn /dev/null "$PROFILE_DIR/airootfs/etc/systemd/system/systemd-networkd.socket"

# Stable capability commands (for example file-manager-1) all dispatch through
# glyph-cap. Their provider mapping lives in one auditable TSV file.
while IFS=$'\t' read -r alias _; do
    [[ -n "$alias" && "$alias" != \#* ]] || continue
    [[ "$alias" =~ ^[a-z0-9][a-z0-9-]*$ ]] || die "invalid capability alias: $alias"
    ln -sfn glyph-cap "$PROFILE_DIR/airootfs/usr/local/bin/$alias"
done <"$PROJECT_DIR/overlay/etc/glyph/capabilities.tsv"

if [[ -n ${PACMAN_CACHE_DIR:-} ]]; then
    [[ "$PACMAN_CACHE_DIR" != *$'\n'* ]] || die "PACMAN_CACHE_DIR contains a newline"
    install -d -m 0755 "$PACMAN_CACHE_DIR"
    sed -i "/^\[options\]$/a CacheDir = $PACMAN_CACHE_DIR" "$PROFILE_DIR/pacman.conf"
fi
if [[ -n ${PACMAN_DOWNLOAD_USER:-} ]]; then
    [[ "$PACMAN_DOWNLOAD_USER" =~ ^[a-zA-Z0-9_-]+$ ]] || die "invalid PACMAN_DOWNLOAD_USER"
    sed -i "/^\[options\]$/a DownloadUser = $PACMAN_DOWNLOAD_USER\nDisableSandbox" "$PROFILE_DIR/pacman.conf"
fi

mapfile -t selected_manifests < <(
    printf '%s\n' "$PROJECT_DIR/packages/core.x86_64"
    [[ "$flavor" == full || "$flavor" == dev ]] && printf '%s\n' "$PROJECT_DIR/packages/apps.x86_64"
    [[ "$flavor" == dev ]] && printf '%s\n' "$PROJECT_DIR/packages/dev.x86_64"
)

glyph_package_file="$(mktemp)"
trap 'rm -f -- "$glyph_package_file"' EXIT
awk '!/^[[:space:]]*(#|$)/ {print $1}' "${selected_manifests[@]}" | LC_ALL=C sort -u >"$glyph_package_file"

merged_package_file="$(mktemp)"
trap 'rm -f -- "$glyph_package_file" "$merged_package_file"' EXIT
awk '!/^[[:space:]]*(#|$)/ {print $1}' "$PROFILE_DIR/packages.x86_64" "$glyph_package_file" \
    | LC_ALL=C sort -u >"$merged_package_file"
install -m 0644 "$merged_package_file" "$PROFILE_DIR/packages.x86_64"

# The live image carries its own installation payload. This makes deployment
# independent of a network checkout and guarantees that live and installed
# environments receive the same files.
payload="$PROFILE_DIR/airootfs/usr/local/share/glyph"
install -d -m 0755 "$payload/rootfs" "$payload/docs"
cp -a -- "$PROJECT_DIR/overlay/." "$payload/rootfs/"
install -m 0644 "$glyph_package_file" "$payload/packages.x86_64"
printf '%s\n' "$flavor" >"$payload/flavor"
install -m 0644 "$PROJECT_DIR/docs/APP_CATALOG.md" "$payload/docs/APP_CATALOG.md"
install -m 0644 "$PROJECT_DIR/docs/ARCHITECTURE.md" "$payload/docs/ARCHITECTURE.md"
install -m 0644 "$PROJECT_DIR/docs/LINUXLINKS_TUI_100.md" "$payload/docs/LINUXLINKS_TUI_100.md"
install -m 0644 "$PROJECT_DIR/LICENSE" "$payload/LICENSE"

replace_profile_setting() {
    local key="$1"
    local value="$2"
    grep -qE "^${key}=" "$PROFILE_DIR/profiledef.sh" || die "profiledef.sh has no $key setting"
    sed -i -E "s|^${key}=.*|${key}=\"${value}\"|" "$PROFILE_DIR/profiledef.sh"
}

replace_profile_setting iso_name glyph-linux
replace_profile_setting iso_label "GLYPH_$(date -u +%Y%m)"
replace_profile_setting iso_publisher "Glyph Linux contributors"
replace_profile_setting iso_application "Glyph Linux text-first Arch workstation"
replace_profile_setting iso_version "$(date -u +%Y.%m.%d)"

# Archiso normalizes overlay files to 0644 unless permissions are declared in
# profiledef.sh. These recursive entries keep every Glyph launcher executable
# in both rootful and rootless builds.
printf '%s\n' \
    'file_permissions["/usr/local/bin/"]="0:0:755"' \
    'file_permissions["/usr/local/lib/glyph/"]="0:0:755"' \
    >>"$PROFILE_DIR/profiledef.sh"

find "$PROFILE_DIR/airootfs/usr/local/bin" "$PROFILE_DIR/airootfs/usr/local/lib/glyph" \
    -type f -exec chmod 0755 {} +

printf 'Prepared Glyph %s profile at %s\n' "$flavor" "$PROFILE_DIR"
if ((profile_only)); then
    exit 0
fi

command -v mkarchiso >/dev/null 2>&1 || die "mkarchiso is missing; install the archiso package"
if [[ -e "$MKARCHISO_WORK" ]]; then
    safe_remove_tree "$MKARCHISO_WORK"
fi

mkarchiso -v -w "$MKARCHISO_WORK" -o "$OUT_DIR" "$PROFILE_DIR"
printf 'Glyph Linux ISO written to %s\n' "$OUT_DIR"
