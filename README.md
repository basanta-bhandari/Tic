# Glyph Linux

This source repository is **Tic**. Its package interface is **TAC**: a TUI
capability layer over Pacman—Tic/Tac, with Pacman doing the real transactions.

Glyph Linux is an unofficial, Arch-based, text-first workstation. It boots to a
small Apple-II-inspired control surface, uses Fish as the interactive shell,
and replaces a conventional graphical desktop with cohesive CLI and TUI
applications.

It is a real Arch system, not a terminal-themed mockup. Pacman, systemd, the
Arch repositories, Linux drivers, filesystems, encryption, networking, audio,
Bluetooth, SSH, and the normal recovery tools remain available underneath the
text interface.

## What is included

- `glyph`: the desktop-like application launcher
- `glyph-control`: settings, hardware, services, logs, and power controls
- `tac`: a guarded TUI around Pacman with stable capability names
- commands such as `file-manager-1`, `editor-2`, and `system-monitor-1`
- `glyph-open`: file-type-aware opener for the text environment
- `glyph-doctor`: concise health report
- `glyph-install`: Archinstall followed by Glyph deployment
- Fish, tmux, Yazi, Neovim, btop, calcurse, Taskwarrior, aerc, Newsboat,
  W3M, Chafa, VisiData, cmus, mpv terminal video, and other focused tools
- NetworkManager/nmtui, PipeWire, BlueZ, UFW, storage and recovery utilities
- No Xorg server, Wayland compositor, display manager, or desktop environment

The default `full` image is intended to cover the jobs expected of an everyday
computer while remaining substantially leaner than a graphical workstation.
The `core` flavor drops most end-user applications for a small base system.

## Build

Build on an up-to-date Arch Linux machine:

```sh
sudo pacman -S --needed archiso qemu-desktop shellcheck
make check
make iso
```

The ISO is written to `out/`. Other flavors:

```sh
make iso FLAVOR=core
make iso FLAVOR=dev
```

The build deliberately derives its bootloader and live-environment machinery
from the locally installed Archiso `releng` profile. This keeps the image aligned
with the current Archiso release rather than freezing a stale copy of the boot
configuration in this repository. Glyph uses Zstandard level 6 for the live
filesystem, favoring fast builds and responsive boot-time decompression over
the smallest possible download.

To boot the result in QEMU:

```sh
make run
```

`make run` uses the newest ISO in `out/`, boots with UEFI when OVMF is available,
and forwards the host CPU to the guest.

## Live environment and installation

The live image logs in as root using the standard Archiso behavior, starts Fish,
and opens the Glyph launcher on TTY1. Press `Esc` to leave any menu. From the
launcher, choose **Install Glyph Linux**. The installer runs the official guided
Archinstall flow and then deploys the Glyph package set and configuration into
the mounted target.

If Archinstall used a target other than `/mnt`, run:

```sh
glyph-deploy /path/to/target
```

The deployer refuses paths that do not look like mounted Arch installations.
It enables NetworkManager, Bluetooth, PipeWire socket activation, periodic
TRIM, and the firewall; changes normal login users to Fish; and keeps the target
at `multi-user.target`.

## Daily use

- `glyph` opens the main workspace.
- `Ctrl+Alt+F2` through `F6` provide clean virtual consoles.
- `tmux` provides persistent windows and splits.
- `glyph-open PATH_OR_URL` chooses an appropriate text application.
- `glyph-control` exposes common system settings.
- `tac` handles update, search, install, removal, and cleanup.
- `tac install file-manager-1` installs its current provider (`nnn`).
- `file-manager-1` launches that provider without making scripts depend on it.
- `glyph-pkg` remains as a compatibility name; Coreutils `tac` is `/usr/bin/tac`.
- `glyph-doctor` checks failed services, disks, memory, connectivity, and updates.
- Set `GLYPH_NO_LAUNCH=1` to prevent the launcher from opening at login.

## Size and graphics

Fish improves interactive shell behavior; it does not render graphics. Glyph's
visual layer is provided by the Linux console, ncurses/dialog, ANSI color, and
applications such as Chafa and mpv's terminal renderer. Images and video are
therefore approximations made from terminal cells. A graphical browser, DRM
video, professional office compatibility, and pixel-perfect media applications
still require a graphical stack.

Arch plus broad firmware cannot reach Alpine-sized images. Glyph stays light by
omitting the graphical stack and long-running desktop services, while retaining
the firmware and recovery coverage expected of a general-purpose machine.

## Project layout

```text
build.sh       creates an Archiso profile and ISO
packages/      package sets for core, full, and development flavors
overlay/       files copied into the live system and installed system
scripts/       validation tools
docs/          architecture and application mapping
repo/          Tic meta-package repository builder and Pacman configuration
```

## Capability catalog and repository

`overlay/etc/glyph/capabilities.tsv` is the single source of truth mapping
stable names to packages and executable commands. `repo/build-meta.sh` turns
that map into normal Arch meta-packages for a local or signed hosted repository.
See the [Tic repository notes](repo/README.md) and the audited
[LinuxLinks list of 100 TUI apps](docs/LINUXLINKS_TUI_100.md).

## Status

The source tree is complete and locally validated. The build supports an
unprivileged user namespace when configured by the host; it needs Archiso,
repository access, and several gigabytes of temporary disk space. The build is
reproducible in structure but, like Arch itself, resolves the current rolling
package versions unless an Arch Linux Archive mirror is configured.

## License

Glyph-specific scripts and configuration are MIT licensed. Included packages
retain their own licenses. Arch Linux is a trademark of its respective owner;
Glyph Linux is not an official Arch Linux project.
