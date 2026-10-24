#!/usr/bin/env bash
set -Eeuo pipefail

readonly RUNE_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
if [[ -d "$RUNE_DIR/.git" && -f "$RUNE_DIR/build.sh" ]]; then
    default_project_dir="$RUNE_DIR"
else
    default_project_dir="$RUNE_DIR/Arca"
fi
readonly PROJECT_DIR="${RUNE_PROJECT_DIR:-$default_project_dir}"

usage() {
    cat <<EOF
Usage: $(basename "$0") [PATH_TO_ISO]

Boot the newest Zenith OS ISO in QEMU. You can also set RUNE_ISO,
RUNE_MEMORY (default: 4096), RUNE_CPUS (default: 4), or RUNE_GL
(auto, 1, or 0; default: auto) for virgl rendering.
EOF
}

case "${1:-}" in
    -h|--help) usage; exit 0 ;;
esac

qemu_command=()
if command -v qemu-system-x86_64 >/dev/null 2>&1; then
    qemu_command=(qemu-system-x86_64)
elif [[ -x "$PROJECT_DIR/.local-tools/root/usr/bin/qemu-system-x86_64" ]]; then
    local_qemu_root="$PROJECT_DIR/.local-tools/root"
    qemu_command=(
        env
        "LD_LIBRARY_PATH=$local_qemu_root/usr/lib"
        "QEMU_MODULE_DIR=$local_qemu_root/usr/lib/qemu"
        "$local_qemu_root/usr/bin/qemu-system-x86_64"
        -L "$local_qemu_root/usr/share/qemu"
    )
else
    printf 'qemu-system-x86_64 is missing. Run %s first.\n' "$RUNE_DIR/install.sh" >&2
    exit 1
fi

iso="${1:-${RUNE_ISO:-}}"
if [[ -z "$iso" ]]; then
    iso="$({
        find "$RUNE_DIR" -maxdepth 1 -type f \( -name 'zenith-os-*.iso' -o -name 'glyph-linux-*.iso' \) -printf '%T@ %p\n' 2>/dev/null
        find "$PROJECT_DIR/out" -maxdepth 1 -type f \( -name 'zenith-os-*.iso' -o -name 'glyph-linux-*.iso' \) -printf '%T@ %p\n' 2>/dev/null
        find "$PROJECT_DIR/out-fixed" -maxdepth 1 -type f \( -name 'zenith-os-*.iso' -o -name 'glyph-linux-*.iso' \) -printf '%T@ %p\n' 2>/dev/null
    } | sort -nr | head -n 1 | cut -d' ' -f2-)"
fi

if [[ -z "$iso" || ! -f "$iso" ]]; then
    printf 'No Zenith ISO was found. Run %s or pass an ISO path.\n' "$RUNE_DIR/install.sh" >&2
    exit 1
fi

memory="${RUNE_MEMORY:-4096}"
cpus="${RUNE_CPUS:-4}"
acceleration=(-accel tcg,thread=multi -cpu max)
if [[ -r /dev/kvm && -w /dev/kvm ]]; then
    acceleration=(-enable-kvm -cpu host)
else
    printf 'KVM is unavailable; using slower software emulation.\n'
fi

qemu_args=(
    -name 'Zenith OS - Imperium'
    "${acceleration[@]}"
    -m "$memory"
    -smp "$cpus"
    -boot d
    -cdrom "$iso"
    -nic user,model=virtio-net-pci
)

gl_mode="${RUNE_GL:-auto}"
case "$gl_mode" in
    auto)
        [[ -r /dev/dri/renderD128 ]] && gl_mode=1 || gl_mode=0
        ;;
    0|1) ;;
    *) printf 'RUNE_GL must be auto, 1, or 0.\n' >&2; exit 2 ;;
esac
if [[ "$gl_mode" == 1 ]]; then
    [[ -r /dev/dri/renderD128 ]] || {
        printf 'RUNE_GL=1 requested, but /dev/dri/renderD128 is not readable.\n' >&2
        exit 1
    }
    qemu_args+=(-display gtk,gl=on -device virtio-vga-gl)
    printf 'Using virgl accelerated guest rendering.\n'
else
    qemu_args+=(-device virtio-vga)
fi

for firmware in \
    "$PROJECT_DIR/.local-tools/root/usr/share/edk2/x64/OVMF.4m.fd" \
    /usr/share/edk2/x64/OVMF.4m.fd \
    /usr/share/edk2-ovmf/x64/OVMF.fd \
    /usr/share/OVMF/OVMF.fd; do
    if [[ -r "$firmware" ]]; then
        qemu_args+=(-bios "$firmware")
        break
    fi
done

printf 'Booting %s with %s MiB RAM and %s vCPUs...\n' "$iso" "$memory" "$cpus"
exec "${qemu_command[@]}" "${qemu_args[@]}"
