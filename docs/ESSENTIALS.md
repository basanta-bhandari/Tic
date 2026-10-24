# Zenith essential-capability contract

Zenith will use one maintained TUI framework fork for every first-party panel.
That gives the system one focus model, theme engine, renderer, command palette,
test harness and accessibility layer instead of collecting unrelated TUIs.

“Independent” means Zenith owns and ships the visible client, pins its source,
and can maintain it without an upstream binary. It does **not** mean forking
stable Linux infrastructure merely to rename it. BlueZ, PipeWire,
NetworkManager/iwd, UDisks, CUPS, systemd and Pacman remain protocol/service
boundaries, like the kernel and drivers; Zenith panels talk to their supported
APIs and remain replaceable.

## One framework fork

The foundation is deliberately undecided until the project owner selects one:

| Candidate | Language | Strength | Cost |
|---|---|---|---|
| [Ratatui](https://github.com/ratatui/ratatui) | Rust | Lightweight, mature widget/rendering core; best fit for privileged and long-lived panels | Kitty graphics and high-level application patterns remain Zenith work |
| [libvaxis](https://github.com/rockorager/libvaxis) | Zig | Modern terminal negotiation, synchronized output, Unicode and Kitty graphics in one repo | Smaller ecosystem and a fast-moving Zig compiler target |
| [Bubble Tea](https://github.com/charmbracelet/bubbletea) | Go | Excellent event/update model and strong fit with Imperium/TUIOS | Common widgets normally come from a second repository, Bubbles |
| [Textual](https://github.com/Textualize/textual) | Python | Fastest route to rich layouts, testing and command palettes | Largest runtime and dependency footprint |

The chosen repository will be forked as `glyph-ui`. Zenith applications will
consume the pinned fork directly; they will not dynamically fall back to the
unmodified upstream package.

## Required first-party surface

The following 35 capabilities are the minimum product surface. Rows marked
“service API” receive an original Zenith UI; the named backend is infrastructure,
not the user experience.

| # | Capability | Zenith-owned module | Stable boundary | Minimum experience |
|---:|---|---|---|---|
| 1 | Home and launcher | Home | Local catalog | Dashboard, tabs, search, quick launch, live status |
| 2 | Interactive shell | Kage | POSIX/process APIs | Fish compatibility, Zenith commands, completions and safe history |
| 3 | Workspace/multiplexer | Imperium | PTYs | Panes, tabs, sessions, detach/restore and command palette |
| 4 | Terminal renderer | Moji | Wayland/PTY | GPU text, Unicode, Kitty graphics and clipboard |
| 5 | Session/compositor | Imperium | Wayland/DRM | Login, displays, workspaces, shortcuts and locking |
| 6 | Software/store | Arca | Pacman/libalpm | Search, descriptions, exact transaction preview and rollback path |
| 7 | Settings | Control | Service APIs | One searchable control surface with reversible changes |
| 8 | Ethernet and Wi-Fi | Connect | NetworkManager/iwd D-Bus | Scan, connect, forget, hotspot, DNS and diagnostics |
| 9 | Bluetooth | Link | BlueZ D-Bus | Discover, pair, trust, connect and battery state |
| 10 | Audio routing/mixer | Sound | PipeWire/WirePlumber | Devices, streams, profiles, volume and mute |
| 11 | Media controls | Now | MPRIS D-Bus | Play/pause, queue, seek, metadata and device keys |
| 12 | Music library/player | Resonance | PipeWire + codecs | Library, playlists, search, gapless playback and lyrics metadata |
| 13 | Video player | Frame | PipeWire + FFmpeg/mpv library boundary | Hardware decode, subtitles, chapters and fullscreen |
| 14 | Image viewer | Lens | Image codecs + Kitty graphics | Browse, zoom, rotate, metadata and contact sheet |
| 15 | File manager | Files | Filesystem/udisks | Copy/move, preview, mounts, search, trash and permissions |
| 16 | Text/code editor | Edit | Filesystem/LSP protocols | Syntax, search, diff, projects and recovery |
| 17 | Spreadsheet/table | Grid | CSV/TSV/XLSX import library | Formula subset, sort/filter, charts and safe export |
| 18 | Documents/PDF | Paper | Poppler/document converters | Read, search, outline, links, print and export |
| 19 | Archives | Pack | libarchive/7zip formats | Inspect, create, extract and encrypted archives |
| 20 | Web browser | Web | HTTP/TLS + browser engine boundary | Tabs, history, downloads, forms and reader mode |
| 21 | Email | Mail | IMAP/SMTP/JMAP | Multiple accounts, threads, search, attachments and PGP |
| 22 | Calendar | Time | CalDAV/iCalendar | Agenda, month/week, reminders and invitations |
| 23 | Notes and tasks | Notes | Local Markdown/Taskwarrior import | Capture, tags, due dates, search and export |
| 24 | Contacts and chat | People | CardDAV/Matrix/XMPP adapters | Contacts, presence, rooms and attachment handoff |
| 25 | Passwords/secrets | Vault | Secret Service/pass-compatible store | Unlock, generate, copy timeout and audit trail |
| 26 | System/process monitor | Pulse | procfs/sysfs | CPU/GPU/RAM/network graphs, process actions and history |
| 27 | Services and logs | Journal | systemd D-Bus/journal | Units, boot timeline, filtering and follow mode |
| 28 | Storage/partitions | Disks | UDisks/LVM/Btrfs tools | Mounts, health, format, encryption, snapshots and recovery warnings |
| 29 | Backup and sync | Preserve | restic/rclone protocols | Profiles, schedule, progress, verification and restore browser |
| 30 | Printing and scanning | Output | CUPS/SANE | Queue, device setup, preview, scan and PDF output |
| 31 | Power/thermal/brightness | Energy | logind/power-profiles/sysfs | Profiles, battery health, inhibitors, suspend and brightness |
| 32 | Notifications | Signal | freedesktop notification protocol | History, actions, urgency, quiet mode and expiry |
| 33 | Clipboard and screenshots | Capture | Wayland data-control/grim | History, sensitive-item expiry, regions and annotations |
| 34 | Installer/update/recovery | Forge | Archinstall/Pacman/Btrfs | Guided install, atomic plan, snapshots, repair and rollback |
| 35 | Accessibility/input | Access | Wayland/input method protocols | Remapping, contrast, scale, screen-reader stream and keyboard-only use |

## Delivery rule

Each module must offer the same operation through its TUI, a documented CLI,
and a structured internal API. A panel may be incomplete, but it may not claim
ownership while silently launching an unrelated stock TUI. Transitional
adapters must be labelled in the UI and tracked for replacement.
