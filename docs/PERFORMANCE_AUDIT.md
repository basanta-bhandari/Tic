# Latency, rendering and UX audit

This is a static audit of the Zenith-owned boot, session and application paths.
It does not pretend that host benchmarks are guest benchmarks. Release QA must
still record `systemd-analyze`, frame timing and input latency from the built
ISO on both integrated Intel and AMD graphics.

## Findings and decisions

| Area | Finding | Resolution |
|---|---|---|
| Kernel | Zenith uses Arch's supported `linux` kernel with normal hardware detection. No trace or benchmark currently implicates scheduling latency. | Keep the supported kernel. Do not carry a low-latency fork until measurements demonstrate a kernel bottleneck. |
| Memory pressure | Zram was already configured at half of RAM, capped at 4 GiB, with zstd and high swap priority. | Retained; this is preferable to early disk swap on lightweight and integrated-GPU machines. |
| Native rendering | Sway, Kitty and Mesa form a direct Wayland path. Intel and AMD Vulkan/Mesa packages are included. | Retained. Fish is a shell, not a renderer; Kitty owns cell rendering and graphics. |
| Kitty input | Default input and repaint batching favored efficiency over immediate response. | Set `input_delay 0` and `repaint_delay 2`, while keeping monitor synchronization to avoid tearing. |
| Sway reloads | `exec_always glyph-wallpaper --sway` created another `swaybg` process on every config reload. | Changed to `exec`, leaving one wallpaper renderer. |
| App launch | Zenith evaluated every catalog command through a Bash *login* shell. That adds profile I/O and may trigger unrelated login hooks. | Use a clean non-login shell during migration. Imperium should eventually launch structured argument arrays directly. |
| Discovery | The old launcher hid every missing command, making optional software undiscoverable. | Added `glyph-store`: one Pacman database read, 100 cached catalog rows, status labels, fuzzy multi-select and one reviewed transaction. |
| Installation safety | The reference Termui permits arbitrary raw install commands, including remote scripts. | Zenith only automates packages found in enabled signed repositories. External entries remain visible but require deliberate manual review. |
| VM graphics | QEMU used a 2D virtio VGA device, so VM animation was not representative of hardware. | `run.sh` now selects virgl automatically when a readable render node exists; `RUNE_GL=0/1` overrides it. |
| Live-media I/O | Archcraft boots with `copytoram=n`, so opening uncached programs from optical/USB media can feel slower than an installed system. | Keep the low-RAM default. Benchmark installed Zenith separately; optionally test `copytoram=y` on machines with ample RAM. |
| Catalog size | Installing every TUI increases ISO size, package synchronization and attack surface, even when applications do not run. | Keep a useful core and make the full 100 discoverable and selectable. The `full` build can remain a QA/demo flavor. |

## Release measurements

Record these on each candidate ISO and installed system:

```text
systemd-analyze
systemd-analyze critical-chain
systemd-analyze blame
systemd-analyze security
```

For the visible path, record time from SDDM submission to the first responsive
Zenith prompt, Kitty key-to-cell latency at 60 Hz and 120 Hz, idle memory after
five minutes, repeated Sway reload memory, and frame pacing while displaying a
Kitty image. Test Intel and AMD integrated graphics with software rendering
disabled, then repeat QEMU QA with virgl and its explicit 2D fallback.
