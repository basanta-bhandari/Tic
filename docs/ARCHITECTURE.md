# Architecture

Zenith derives its ISO plumbing, graphical package base, and visual assets from
a pinned official Archcraft profile. Zenith then owns the default session:

```text
Archcraft / Arch Linux
└── Imperium session (transitional Sway adapter)
    └── Kitty GPU terminal
        └── imperium (`glyph-mux` compatibility backend)
            ├── Kage command surfaces
            ├── Zenith Home and first-party panels
            ├── themes and wallpapers
            └── native GUI escape hatches
```

Imperium currently delegates terminal emulation, rendering, tabs, and
splits to Kitty's remote-control protocol. Zellij remains installed for true
PTY persistence and remote detach/reattach. This keeps the custom Zenith control
plane small enough to audit while leaving room for a future PTY-owning daemon.

Wallpapers are not embedded wholesale. `glyph-wallpaper` reads the generated
category indexes in `basanta-bhandari/walls`, validates category and filename
segments, downloads one selected image over HTTPS, verifies that it is an image,
and stores it in the user's XDG data directory. An offline-generated gradient
is always available.

Zenith intentionally remains a thin product layer over Arch rather than forking
the package manager, kernel, init system, or repositories.

## Layers

1. Arch Linux supplies the kernel, firmware, drivers, Pacman, systemd, security
   updates, and package ecosystem.
2. Archcraft's pinned Archiso profile supplies BIOS/UEFI boot, the graphical
   base, visual packages, live root filesystem, and recovery environment.
3. `overlay/` supplies Zenith's transitional Sway/Kitty session, Kage environment, control surfaces,
   opener, installer bridge, and system defaults. Zenith Home is currently a compact
   Python/curses surface so its interaction model can be tested before the shared
   native UI framework is selected.
4. Focused upstream applications provide editing, files, web, mail, calendars,
   monitoring, documents, and media.

All control surfaces are replaceable clients. The underlying applications remain
available directly and preserve their normal configuration formats. A panel
failure therefore cannot lock the user out of the system.

## Terminal UI transition

Zenith Home now uses a responsive curses dashboard with the Signal theme, live
status, category tabs, search and quick launch. `dialog` remains only as a small
recovery/migration fallback. Once the project owner selects the framework in
`docs/ESSENTIALS.md`, Home and every first-party panel move onto the maintained
`glyph-ui` fork. ANSI/curses paths continue to degrade gracefully on serial
terminals and recovery TTYs.

Kage retains Fish compatibility because completion, history, discoverability, and sane
interactive defaults are more important here than strict POSIX syntax. System
scripts remain Bash so boot and recovery never depend on Fish behavior.

## Application contract

- Every Zenith TUI operation has a direct CLI escape hatch.
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
high-risk installer logic upstream while letting Zenith own its user experience.

## Release model

The build fetches the official Archcraft ISO profile at the commit pinned by
`scripts/fetch-archcraft-profile.sh`. `ARCHCRAFT_REF` can deliberately select a
different revision. Package names are validated before the build; package
versions intentionally track Arch and Archcraft rolling repositories. Release
builders should also pin dated package mirrors when byte-for-byte dependency
resolution matters.
