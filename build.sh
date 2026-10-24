#!/usr/bin/env bash
set -euo pipefail

readonly PROJECT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"

flavor="full"
archiso_profile="${ARCHISO_PROFILE:-}"
profile_only=0

usage() {
    cat <<'EOF'
Usage: ./build.sh [OPTIONS]

Build a Zenith OS image derived from the official Archcraft ISO profile.

Options:
  --flavor core|full|dev    Package set to include (default: full)
  --archiso-profile PATH   Override the Archcraft profile (mainly for testing)
  --profile-only           Prepare work/profile but do not invoke mkarchiso
  -h, --help               Show this help

Environment:
  OUT_DIR                  ISO destination (default: PROJECT/out)
  PACMAN_CACHE_DIR         Writable package cache override for Archiso
  PACMAN_DOWNLOAD_USER     Pacman download user override (e.g. root in userns)
  ARCHCRAFT_REF            Upstream commit/tag override
EOF
}

die() {
    printf 'glyph-build: %s\n' "$*" >&2
    exit 1
}

safe_remove_tree() {
    local target="$1"
    case "$target" in
        "$PROJECT_DIR"/work/*|"$PROJECT_DIR"/work-*/*) ;;
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

if [[ -z "$archiso_profile" ]]; then
    archiso_profile="$($PROJECT_DIR/scripts/fetch-archcraft-profile.sh)"
fi

[[ -r "$archiso_profile/profiledef.sh" ]] || die "no Archiso profile at $archiso_profile"
[[ -r "$archiso_profile/packages.x86_64" ]] || die "profile has no packages.x86_64"

readonly WORK_DIR="${WORK_DIR:-$PROJECT_DIR/work}"
readonly OUT_DIR="${OUT_DIR:-$PROJECT_DIR/out}"
readonly PROFILE_DIR="$WORK_DIR/profile"
readonly MKARCHISO_WORK="$WORK_DIR/mkarchiso"

case "$WORK_DIR" in
    "$PROJECT_DIR"/work|"$PROJECT_DIR"/work-*) ;;
    *) die "WORK_DIR must be PROJECT/work or a PROJECT/work-* staging directory" ;;
esac

"$PROJECT_DIR/scripts/check.sh"

if [[ -e "$PROFILE_DIR" ]]; then
    safe_remove_tree "$PROFILE_DIR"
fi
install -d -m 0755 "$WORK_DIR" "$OUT_DIR"
cp -a -- "$archiso_profile" "$PROFILE_DIR"
cp -a -- "$PROJECT_DIR/overlay/." "$PROFILE_DIR/airootfs/"

# Pacman 7 requires a local-database format marker. Some Archcraft profiles
# ship an empty local database directory without it; packages install, but a
# later `pacman -Q --sysroot` then aborts while mkarchiso writes pkglist.txt.
# Copy the marker expected by the host libalpm driving this build.
if [[ -r /var/lib/pacman/local/ALPM_DB_VERSION ]]; then
    install -D -m 0644 /var/lib/pacman/local/ALPM_DB_VERSION \
        "$PROFILE_DIR/airootfs/var/lib/pacman/local/ALPM_DB_VERSION"
fi

# Archcraft's generic profile advertises a proprietary-NVIDIA image and a
# Plymouth hook even when neither package is selected. Glyph's portable image
# uses the normal KMS initramfs for Intel, AMD and Nouveau instead of emitting
# a broken second image and boot entry.
rm -f -- \
    "$PROFILE_DIR/airootfs/etc/mkinitcpio.d/linux-nvidia.preset" \
    "$PROFILE_DIR/airootfs/etc/mkinitcpio.conf.d/archiso-nvidia.conf" \
    "$PROFILE_DIR/efiboot/loader/entries/03-archiso-linux-nvidia.conf"
if [[ -d "$PROFILE_DIR/airootfs/etc/mkinitcpio.conf.d" ]]; then
    find "$PROFILE_DIR/airootfs/etc/mkinitcpio.conf.d" -maxdepth 1 -type f -name '*.conf' \
        -exec sed -i -E 's/[[:space:]]+plymouth([[:space:]])/\1/' {} +
fi
if [[ -f "$PROFILE_DIR/syslinux/archiso_sys-linux.cfg" ]]; then
    sed -i '/^# NVIDIA Proprietary$/,/^# Nomodeset$/{ /^# Nomodeset$/!d; }' \
        "$PROFILE_DIR/syslinux/archiso_sys-linux.cfg"
fi
find "$PROFILE_DIR" -type f \
    \( -path "$PROFILE_DIR/efiboot/*" -o -path "$PROFILE_DIR/syslinux/*" \) \
    \( -name '*.conf' -o -name '*.cfg' \) -exec sed -i \
    -e 's/Archcraft/Zenith OS/g' -e 's/ quiet splash / quiet /g' {} +
# Archiso's live root account already exists, so its customization pass does
# not populate it from /etc/skel. Seed missing dotfiles explicitly while
# retaining root-only overrides such as .zprofile and the Fish shim.
cp -a -n -- "$PROFILE_DIR/airootfs/etc/skel/." "$PROFILE_DIR/airootfs/root/"
if grep -q '^liveuser:' "$PROFILE_DIR/airootfs/etc/passwd" 2>/dev/null; then
    install -d -m 0755 "$PROFILE_DIR/airootfs/home/liveuser"
    cp -a -- "$PROFILE_DIR/airootfs/etc/skel/." "$PROFILE_DIR/airootfs/home/liveuser/"
    sed -i -E 's|^(liveuser:[^:]*:[^:]*:[^:]*:[^:]*:[^:]*):[^:]*$|\1:/usr/bin/kage|' \
        "$PROFILE_DIR/airootfs/etc/passwd"
fi
# Releng uses zsh for the live root account and has historically enabled
# systemd-networkd's socket. Glyph enters Fish from root's zprofile and gives
# NetworkManager exclusive ownership of networking.
ln -sfn /dev/null "$PROFILE_DIR/airootfs/etc/systemd/system/systemd-networkd.socket"

# Archcraft's profile expects its mirrorlist package on the build host. Glyph
# can be built from plain Arch, so use Archcraft's canonical repository URL for
# the host-side pacstrap. The installed image receives the maintained
# archcraft-mirrorlist package normally.
if grep -q 'archcraft-mirrorlist' "$PROFILE_DIR/pacman.conf"; then
    sed -i 's|Include = /etc/pacman.d/archcraft-mirrorlist|Server = https://packages.archcraft.io/$arch|' \
        "$PROFILE_DIR/pacman.conf"
fi
if grep -q '^DownloadUser[[:space:]]*=' "$PROFILE_DIR/pacman.conf"; then
    sed -i -E 's/^DownloadUser[[:space:]]*=.*/DownloadUser = root/' "$PROFILE_DIR/pacman.conf"
    grep -q '^DisableSandbox' "$PROFILE_DIR/pacman.conf" || \
        sed -i '/^DownloadUser[[:space:]]*=/a DisableSandbox' "$PROFILE_DIR/pacman.conf"
fi

# Custom packages are built into a small local Arca repository. Requiring the
# package here prevents an ISO that silently falls back to upstream Fish while
# still claiming to contain Kage.
if grep -qx 'kage-shell' "$PROJECT_DIR/packages/core.x86_64"; then
    mapfile -t kage_shell_packages < <(
        compgen -G "$PROJECT_DIR/repo/out/kage-shell-*.pkg.tar.zst" | LC_ALL=C sort -V
    )
    ((${#kage_shell_packages[@]} > 0)) || \
        die "Kage package missing; run repo/build-custom.sh first"
    kage_shell_package="${kage_shell_packages[-1]}"
    [[ -r "$PROJECT_DIR/repo/out/arca.db.tar.zst" ]] || \
        die "Arca repository database missing; run repo/build-custom.sh first"
    [[ "$PROJECT_DIR" != *[[:space:]]* ]] || \
        die "custom-package builds currently require a project path without whitespace"
    printf '\n[arca]\nSigLevel = Optional TrustAll\nServer = file://%s/repo/out\n' \
        "$PROJECT_DIR" >>"$PROFILE_DIR/pacman.conf"
fi

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
    printf '%s\n' "$PROJECT_DIR/packages/archcraft-base.x86_64"
    printf '%s\n' "$PROJECT_DIR/packages/core.x86_64"
    printf '%s\n' "$PROJECT_DIR/packages/session.x86_64"
    [[ "$flavor" == full || "$flavor" == dev ]] && printf '%s\n' "$PROJECT_DIR/packages/apps.x86_64"
    [[ "$flavor" == dev ]] && printf '%s\n' "$PROJECT_DIR/packages/dev.x86_64"
)

glyph_package_file="$(mktemp)"
trap 'rm -f -- "$glyph_package_file"' EXIT
awk '!/^[[:space:]]*(#|$)/ {print $1}' "${selected_manifests[@]}" | LC_ALL=C sort -u >"$glyph_package_file"

merged_package_file="$(mktemp)"
trap 'rm -f -- "$glyph_package_file" "$merged_package_file"' EXIT
install -m 0644 "$glyph_package_file" "$merged_package_file"
install -m 0644 "$merged_package_file" "$PROFILE_DIR/packages.x86_64"

# The live image carries its own installation payload. This makes deployment
# independent of a network checkout and guarantees that live and installed
# environments receive the same files.
payload="$PROFILE_DIR/airootfs/usr/local/share/glyph"
install -d -m 0755 "$payload/rootfs" "$payload/docs" "$payload/packages"
cp -a -- "$PROJECT_DIR/overlay/." "$payload/rootfs/"
install -m 0644 "$glyph_package_file" "$payload/packages.x86_64"
printf '%s\n' "$flavor" >"$payload/flavor"
install -m 0644 "$PROJECT_DIR/docs/APP_CATALOG.md" "$payload/docs/APP_CATALOG.md"
install -m 0644 "$PROJECT_DIR/docs/ARCHITECTURE.md" "$payload/docs/ARCHITECTURE.md"
install -m 0644 "$PROJECT_DIR/docs/LINUXLINKS_TUI_100.md" "$payload/docs/LINUXLINKS_TUI_100.md"
install -m 0644 "$PROJECT_DIR/docs/COSMIC_SHORTCUTS.md" "$payload/docs/COSMIC_SHORTCUTS.md"
install -m 0644 "$PROJECT_DIR/LICENSE" "$payload/LICENSE"
if [[ -n ${kage_shell_package:-} ]]; then
    install -m 0644 "$kage_shell_package" "$payload/packages/"
fi

replace_profile_setting() {
    local key="$1"
    local value="$2"
    grep -qE "^${key}=" "$PROFILE_DIR/profiledef.sh" || die "profiledef.sh has no $key setting"
    sed -i -E "s|^${key}=.*|${key}=\"${value}\"|" "$PROFILE_DIR/profiledef.sh"
}

replace_profile_setting iso_name zenith-os
replace_profile_setting iso_label "ZENITH_$(date -u +%Y%m)"
replace_profile_setting iso_publisher "Zenith OS contributors"
replace_profile_setting iso_application "Zenith OS text-first Arch workstation"
replace_profile_setting iso_version "$(date -u +%Y.%m.%d)"

# The broad TUI catalog contains many static binaries and small runtime files.
# Zstandard keeps image creation and live boot responsive without changing the
# installed footprint; level 6 is a deliberate size/speed compromise for this
# unusually broad live catalog.
grep -q '^airootfs_image_tool_options=' "$PROFILE_DIR/profiledef.sh" || \
    die "profiledef.sh has no airootfs_image_tool_options setting"
sed -i -E \
    "s|^airootfs_image_tool_options=.*|airootfs_image_tool_options=('-comp' 'zstd' '-Xcompression-level' '6')|" \
    "$PROFILE_DIR/profiledef.sh"

# Archiso normalizes overlay files to 0644 unless permissions are declared in
# profiledef.sh. These recursive entries keep every Glyph launcher executable
# in both rootful and rootless builds.
printf '%s\n' \
    'file_permissions["/usr/local/bin/"]="0:0:755"' \
    'file_permissions["/usr/local/lib/glyph/"]="0:0:755"' \
    'file_permissions["/home/liveuser/"]="1000:1000:755"' \
    >>"$PROFILE_DIR/profiledef.sh"

find "$PROFILE_DIR/airootfs/usr/local/bin" "$PROFILE_DIR/airootfs/usr/local/lib/glyph" \
    -type f -exec chmod 0755 {} +

printf 'Prepared Zenith %s profile at %s\n' "$flavor" "$PROFILE_DIR"
if ((profile_only)); then
    exit 0
fi

local_tool_root="$PROJECT_DIR/.local-tools/root"
if ! command -v mkarchiso >/dev/null 2>&1; then
    if [[ -x "$local_tool_root/usr/bin/mkarchiso" ]]; then
        export PATH="$local_tool_root/usr/bin:$PATH"
    else
        die "mkarchiso is missing; run install.sh or install the archiso package"
    fi
fi
# A caller may already have placed the project-local mkarchiso on PATH.  In
# that case it still needs the matching project-local shared libraries (most
# visibly libisoburn for xorriso).  Key this off the resolved executable rather
# than only the command-not-found fallback above.
mkarchiso_path="$(readlink -f -- "$(command -v mkarchiso)")"
if [[ "$mkarchiso_path" == "$local_tool_root"/* ]]; then
    export LD_LIBRARY_PATH="$local_tool_root/usr/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
    printf 'Using the project-local Archiso toolchain at %s\n' "$local_tool_root"
fi
if [[ -e "$MKARCHISO_WORK" ]]; then
    safe_remove_tree "$MKARCHISO_WORK"
fi

mkarchiso -v -w "$MKARCHISO_WORK" -o "$OUT_DIR" "$PROFILE_DIR"
printf 'Zenith OS ISO written to %s\n' "$OUT_DIR"
