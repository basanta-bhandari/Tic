# Zenith redesign contract

## Product boundary

Zenith is not a themed Arch desktop. The final product keeps the Linux kernel,
filesystems, drivers, firmware, systemd, Pacman, core utilities and essential
protocol/media libraries as infrastructure. Everything the user directly sees
from login onward is Zenith-owned and uses only Zig, Rust, Assembly, Python or
Go. Reusing a library is acceptable; exposing an upstream application's stock
interface as the Zenith shell is not.

The current Sway + Kitty image is a transitional reference implementation. It
exists to validate boot, drivers, installation and interaction decisions while
the owned components replace it. It must never be described as the completed
custom environment.

The minimum owned product surface is the 35-capability contract in
`docs/ESSENTIALS.md`. It includes networking, Bluetooth, audio, media, files,
images, spreadsheets, documents, communications, monitoring, recovery and
accessibility. A capability is not considered first-party if its panel merely
launches an unrelated upstream TUI.

| Layer | Transitional implementation | Target Zenith component |
|---|---|---|
| Disk format | Archinstall-selected ext4/Btrfs | Standard Btrfs by default, with Zenith-owned layout, snapshots and recovery UX |
| Login/session | SDDM and `glyph-session` | **Imperium**, with an owned greeter and session supervisor |
| Wayland compositor | Sway/wlroots | **Imperium**, a compositor built on maintained Wayland protocols and rendering primitives |
| Terminal renderer | Kitty | **Moji**, a Rust GPU terminal surface with Kitty graphics compatibility |
| Interactive shell | Upstream Fish configuration | **Kage**, the pinned Fish fork with owned defaults, commands and release lifecycle |
| TWM/multiplexer | Kitty remote control and `glyph-mux` | **Imperium**, the Zenith Go workspace derived from pinned TUIOS source |
| Alternate environment | Source-only PY_DOS checkout | PY_DOS packaged as an Imperium workspace with persistent user storage |
| Software catalog | Bash Arca plus Python `glyph-store` | **Arca**, a Rust transaction service and custom store UI |
| Home/control center | Python/curses Zenith Home plus migration scripts | Native panels sharing the selected `glyph-ui` fork and Imperium interaction model |

The custom filesystem work is deliberately a layout and recovery experience,
not a new on-disk filesystem or kernel module. Reinventing ext4/Btrfs would
reduce reliability, recovery-tool compatibility and hardware coverage without
making the visible OS more original.

## Experience

The prototype boots through SDDM into a deliberately empty Sway session
containing a fullscreen Kitty surface. The target boots **Zenith OS** into
**Imperium**, which presents the Moji terminal surface and owns workspace policy. Its interaction
model follows TUIOS: modal window management,
event-driven rendering, BSP panes, persistent workspaces, a session rail,
command palette, fuzzy launcher, zoom, popups, mouse support, scrollback, and
Kitty graphics passthrough. The COSMIC-derived shortcuts remain available at
the outer Sway layer.

Imperium is derived from the pinned MIT-licensed TUIOS engine. Zenith-specific
branding, defaults and integrations must remain a clearly maintained patch
layer so upstream security and terminal-emulation fixes can be rebased.

PyDOS will be packaged as an alternate workspace launched from the palette or
with `pydos`. It is not PID 1 and does not replace Fish: it provides the persistent
DOS-style virtual filesystem, RubOS applications and educational shell inside
a normal protected Linux user session.

## Language boundary

New Zenith-owned runtime code is limited to:

- Go for Imperium, Arca and long-running services.
- Rust for security-sensitive parsers, installers and system utilities.
- Zig for small native utilities and portable low-level components.
- Python for PyDOS, build orchestration and non-privileged integration tools.
- Assembly only for measured boot or architecture-specific code that cannot be
  expressed safely in the languages above.

Shell scripts are migration-only and must not remain in the final runtime
image. Declarative formats such as JSON, TOML, desktop entries and systemd unit
files are configuration rather than implementation languages.

This restriction cannot apply to the Linux/Archcraft base or third-party
applications: Linux, Sway, Kitty, Fish, Mesa and system libraries contain C,
C++, Rust and other upstream implementation languages. Their source is not
Zenith-owned.

## Composition

1. Archcraft profile, repository and boot structure.
2. Linux, systemd, drivers, Mesa and integrated-GPU acceleration.
3. Sway as a hidden Wayland policy layer.
4. Kitty as the graphical terminal renderer.
5. Imperium as the visible multiplexer/window manager.
6. Fish as the default Unix shell; PyDOS as an alternate Python workspace.
7. Arca as the curated package and capability interface over Pacman.

Every external or maintained-fork source is pinned in `upstreams.lock.json`. Builds must verify
the checked-out commit and retain license notices. Network-fetched themes and
wallpapers are data, cached per user, and never executed.

Kage is packaged as `kage-shell`, while retaining `/usr/bin/fish` and
Fish language compatibility. The maintained delta adds a Kage greeting,
read-only `$KAGE_SHELL_VERSION`/`$KAGE_SHELL_VARIANT` identity variables, and
an explicit `/usr/bin/kage` launcher. The former `$GLYPH_SHELL_*` variables and
`/usr/bin/glyph-shell` remain migration aliases. The image builder refuses to
substitute the stock Arch package if the pinned fork package has not been built.

## Migration order

1. Replace `glyph-mux` with the pinned Go engine and Zenith configuration.
2. Package pinned PyDOS and expose it through the launcher and palette.
3. Rewrite Arca in Go or Rust while retaining the current capability TSV as a
   migration input.
4. Replace runtime Bash launchers with Go/Rust/Python entry points.
5. Replace the Bash image builder with Python orchestration.
6. Reject disallowed Zenith-owned source extensions in CI.
