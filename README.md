# Zenith OS

**Arca** is the distribution's curated package chest: a TUI capability layer
over Pacman, with Pacman doing the real transactions underneath.

Zenith OS is an unofficial, Archcraft-derived, terminal-first workstation.
It boots into the responsive Zenith Home, uses the Fish-compatible **Kage**
shell, manages its surfaces through **Imperium**, and installs curated software
through **Arca**. Kitty and Sway are transitional rendering infrastructure while
the owned compositor/workspace matures.

Archcraft and Arch Linux are independent upstream projects; Zenith is not an
official edition of either project. Their packages and artwork retain their
respective licenses and trademarks.

It is a real Arch system, not a terminal-themed mockup. Pacman, systemd, the
Arch repositories, Linux drivers, filesystems, encryption, networking, audio,
Bluetooth, SSH, and the normal recovery tools remain available underneath the
text interface.

## What is included

- `zenith`: the responsive Home dashboard and application launcher
- `imperium`: the transitional compositor/workspace command backed by Kitty
  and Sway; the pinned TUIOS fork is its owned engine source
- a pinned **PY_DOS** source input for the planned alternate workspace; it is
  not yet shipped as a runtime application
- **Kage**, a compile-checked Fish fork packaged separately from Arch's
  stock Fish while retaining Fish language and command compatibility
- `glyph-theme`: live terminal and wallpaper palettes
- `glyph-wallpaper`: indexed, on-demand wallpaper installation from
  `basanta-bhandari/walls`
- `glyph-control`: settings, hardware, services, logs, and power controls
- `arca`: a guarded TUI around Pacman with stable capability names
- `glyph-store`: a searchable, multi-select catalog of 100 TUI applications
  with descriptions and Installed/Available/External status
- commands such as `file-manager-1`, `editor-2`, and `system-monitor-1`
- `glyph-open`: file-type-aware opener for the text environment
- `glyph-doctor`: concise health report
- `glyph-install`: Archinstall followed by Zenith deployment
- Kitty, Kage/Fish, Zellij, Yazi, Neovim, btop, calcurse, Taskwarrior, aerc, Newsboat,
  W3M, Chafa, VisiData, cmus, mpv terminal video, and other focused tools
- NetworkManager/nmtui, PipeWire, BlueZ, UFW, storage and recovery utilities
- Sway/Wayland for GPU rendering and controlled native applications such as VLC

The default `full` image is intended to cover the jobs expected of an everyday
computer while remaining substantially leaner than a graphical workstation.
The `core` flavor drops most end-user applications for a small base system.

## Build

Build on an up-to-date Arch Linux machine. The builder fetches a pinned copy of
Archcraft's official ISO profile and layers Zenith over it:

```sh
sudo pacman -S --needed archiso qemu-desktop shellcheck cmake jq rust
make check
make custom-packages
sudo make iso
```

The ISO is written to `out/`. Other flavors:

```sh
make iso FLAVOR=core
make iso FLAVOR=dev
```

The maintained Fish and TUIOS forks plus PY_DOS are locked to exact commits in
`upstreams.lock.json`. Fetch and verify all three with:

```sh
python tools/fetch_upstreams.py
```

`make custom-packages` builds the pinned Kage fork into `repo/out` and
refreshes the local Arca database. The ISO build refuses to substitute stock
Fish when this package is absent.

Set `ARCHCRAFT_REF` to test another upstream Archcraft revision, or pass
`--archiso-profile PATH` for fixture and recovery builds. Zenith uses Zstandard
level 6 for the live filesystem, favoring fast builds and responsive boot-time
decompression over the smallest possible download.

To boot the result in QEMU:

```sh
make run
```

`make run` uses the newest ISO in `out/`, boots with UEFI when OVMF is available,
and forwards the host CPU to the guest.

## Live environment and installation

The Archcraft live user automatically enters the Zenith Imperium session. Sway
opens one fullscreen Kitty surface running Kage and `imperium`; the ordinary
TTYs remain available for recovery. From the launcher, choose **Install Zenith
OS**. The installer runs the official guided Archinstall flow and then deploys
the Zenith package set and configuration into the mounted target.

If Archinstall used a target other than `/mnt`, run:

```sh
glyph-deploy /path/to/target
```

The deployer refuses paths that do not look like mounted Arch installations.
It enables NetworkManager, Bluetooth, PipeWire socket activation, periodic
TRIM, and the firewall; changes normal login users to Kage/Fish; and keeps the target
at `multi-user.target`.

## Daily use

- `zenith` opens the main workspace (`glyph` is a compatibility alias).
- `Ctrl+Alt+F2` through `F6` provide clean virtual consoles.
- `imperium` provides compositor/workspace control, tabs, panes, and overlays;
  `glyph-mux` remains a migration alias.
- `kage` opens the Fish-compatible Zenith shell.
- Zellij remains available when detach/reattach persistence is required.
- `glyph-theme` switches coordinated Kitty and wallpaper palettes live.
- `glyph-wallpaper install` browses categories such as `nord`, `digital`, and
  `nature` from the indexed GitHub wallpaper repository and downloads only the
  selected image.
- `glyph-open PATH_OR_URL` chooses an appropriate text application.
- `glyph-control` exposes common system settings.
- `arca` handles update, search, install, removal, and cleanup.
- `glyph-store` lets users choose optional tools from the curated 100-app list;
  it previews the exact Pacman transaction and never executes remote scripts.
- `arca install file-manager-1` installs its current provider (`nnn`).
- `file-manager-1` launches that provider without making scripts depend on it.
- `glyph-pkg` remains as a compatibility name.
- `glyph-doctor` checks failed services, disks, memory, connectivity, and updates.
- Set `ZENITH_NO_LAUNCH=1` (or legacy `GLYPH_NO_LAUNCH=1`) to prevent Home from opening at login.

## Graphics model

Kage improves shell behavior; Kitty performs transitional GPU rendering. Zenith runs on a
small Sway/Wayland session, so it supports accurate fonts, transparency,
wallpapers, Kitty's graphics protocol, clipboard integration, native video, and
GUI escape hatches such as VLC without exposing a conventional desktop shell.
`glyph-open` renders images through Kitty when possible and opens video in VLC
inside a graphical session, with Chafa and terminal-cell mpv as TTY fallbacks.

This graphical foundation makes Zenith larger than its earlier console-only
image. The design optimizes the running environment and interaction model, not
the ISO download size.

## Project layout

```text
build.sh       creates an Archiso profile and ISO
packages/      package sets for core, full, and development flavors
overlay/       files copied into the live system and installed system
scripts/       validation tools
docs/          architecture and application mapping
repo/          Arca meta-package repository builder and Pacman configuration
```

## Capability catalog and repository

`overlay/etc/glyph/capabilities.tsv` is the single source of truth mapping
stable names to packages and executable commands. `repo/build-meta.sh` turns
that map into normal Arch meta-packages for a local or signed hosted repository.
See the [Arca repository notes](repo/README.md) and the audited
[LinuxLinks list of 100 TUI apps](docs/LINUXLINKS_TUI_100.md).
The [redesign contract](docs/REDESIGN.md) defines how TUIOS and PY_DOS compose
and where the Zig/Rust/Assembly/Python/Go restriction applies.
The [essential-capability contract](docs/ESSENTIALS.md) defines the 35
first-party surfaces and the four candidates for Zenith's single maintained UI
framework fork.
The [performance audit](docs/PERFORMANCE_AUDIT.md) records the current latency,
rendering and UX findings plus the measurements required for release QA.

## Status

The source tree is complete and locally validated. The build supports an
unprivileged user namespace when configured by the host; it needs Archiso,
repository access, and several gigabytes of temporary disk space. The build is
reproducible in structure but, like Arch itself, resolves the current rolling
package versions unless an Arch Linux Archive mirror is configured.

## License

Zenith-specific scripts and configuration are MIT licensed. Included packages
retain their own licenses. Arch Linux is a trademark of its respective owner;
Zenith OS is not an official Arch Linux project.
