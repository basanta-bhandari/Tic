#!/usr/bin/env bash
# Minimal shape fixture used to test Glyph's profile composition. This is not a
# bootable profile; real builds derive from /usr/share/archiso/configs/releng.
iso_name="archlinux"
iso_label="ARCH_202601"
iso_publisher="Arch Linux"
iso_application="Arch Linux Live/Rescue CD"
iso_version="2026.01.01"
install_dir="arch"
buildmodes=('iso')
bootmodes=('bios.syslinux.mbr' 'uefi-x64.systemd-boot.esp')
arch="x86_64"
pacman_conf="pacman.conf"
airootfs_image_type="squashfs"
airootfs_image_tool_options=(-comp zstd)
file_permissions=()
