# Architecture

Glyph intentionally remains a thin product layer over Arch rather than forking
the package manager, kernel, init system, or repositories.

## Layers

1. Arch Linux supplies the kernel, firmware, drivers, Pacman, systemd, security
   updates, and package ecosystem.
2. Archiso supplies BIOS/UEFI boot, the live root filesystem, and recovery
   environment.
3. `overlay/` supplies Glyph's branding, Fish environment, control surfaces,
   opener, installer bridge, and system defaults.
4. Focused upstream applications provide editing, files, web, mail, calendars,
   monitoring, documents, and media.

All launchers are intentionally replaceable shell programs. The underlying
applications remain available directly and preserve their normal configuration
formats. A launcher failure therefore cannot lock the user out of the system.

## Why dialog and the Linux console

`dialog` is mature, tiny, available in the official Arch repositories, and
works directly on the kernel virtual console and over SSH. This avoids pulling
in a display server, compositor, browser engine, or widget toolkit. ANSI and
ncurses degrade gracefully on serial terminals.

Fish is the user shell because completion, history, discoverability, and sane
interactive defaults are more important here than strict POSIX syntax. System
scripts remain Bash so boot and recovery never depend on Fish behavior.

## Application contract

- Every Glyph TUI operation has a direct CLI escape hatch.
- The launcher never owns user data.
- Pacman remains the single source of truth for installed software.
- Systemd remains the single source of truth for services.
- Configuration is conventional files under `/etc` and `$XDG_CONFIG_HOME`.
- No service listens on the network by default.
- Destructive package and power actions require confirmation.

## Installation model

`glyph-install` delegates partitioning, encryption, bootloader selection, users,
and locale to Archinstall. `glyph-deploy` then installs the selected package
manifest, copies the same root overlay used by the live image, and applies a
small idempotent post-install script inside the target. This division keeps the
high-risk installer logic upstream while letting Glyph own its user experience.

## Release model

The build consumes the Archiso profile installed on the builder. This keeps boot
details compatible with the installed Archiso version. Package names are
validated before the build; package versions intentionally track Arch rolling
release repositories. Release builders should pin a dated Arch Linux Archive
mirror when byte-for-byte dependency resolution matters.
