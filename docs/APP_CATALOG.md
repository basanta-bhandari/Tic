# Application catalog

| Everyday role | Glyph default | Direct command |
|---|---|---|
| Workspace / start menu | Glyph launcher | `glyph` |
| File manager | Yazi | `yazi` |
| Text and code editor | Neovim | `nvim` |
| Simple editor / recovery | Nano | `nano` |
| Web browser | W3M | `w3m URL` |
| Email | aerc | `aerc` |
| RSS reader | Newsboat | `newsboat` |
| Calendar | Calcurse | `calcurse` |
| Tasks | Taskwarrior | `task` |
| Spreadsheet / data | VisiData | `vd FILE` |
| Markdown reader | Glow | `glow FILE` |
| Presentations | Presenterm | `presenterm FILE` |
| PDF text | Poppler plus Less | `glyph-open FILE.pdf` |
| Images | Chafa | `glyph-open IMAGE` |
| Music | cmus | `cmus` |
| Video | mpv terminal cells | `mpv --vo=tct VIDEO` |
| System monitor | btop | `btop` |
| Disk usage | ncdu / dua / duf | `ncdu` |
| Process list | procs | `procs` |
| Wi-Fi / network | NetworkManager | `nmtui` / `nmcli` |
| Bluetooth | BlueZ | `bluetoothctl` |
| Audio mixer | PulseMixer | `pulsemixer` |
| Power and brightness | power-profiles-daemon | `powerprofilesctl` |
| Calculator | libqalculate | `qalc` |
| Printing | CUPS CLI | `lp`, `lpstat`, `lpadmin` |
| Scanning | SANE | `scanimage` |
| Git | LazyGit | `lazygit` |
| Packages | TAC over Pacman | `tac` / `pacman` |
| Settings | Glyph Control | `glyph-control` |
| Diagnostics | Glyph Doctor | `glyph-doctor` |
| Multiplexing | tmux | `tmux` |
| Backups / sync | Restic and rclone | `restic` / `rclone` |
| Torrents | Transmission CLI | `transmission-cli` |
| Password store | pass | `pass` |
| SSH | OpenSSH | `ssh HOST` |

## Stable capability commands

Glyph also exposes role-based names whose providers may change without breaking
habits or scripts. Examples include `file-manager-1` → `nnn`,
`file-manager-2` → `yazi`, `editor-1` → `nvim`, `editor-2` → `hx`, and
`package-manager-1` → `tac`. The complete authoritative mapping is
`/etc/glyph/capabilities.tsv`; browse it with `tac list`.

## Deliberate limitations

Text cells cannot provide a standards-complete modern web browser, pixel-perfect
office suite, color-managed image editor, or efficient video interface. W3M,
VisiData, Chafa, and mpv's terminal output cover useful subsets; users needing
the full graphical equivalents can install a Wayland stack without replacing
the Glyph environment.
