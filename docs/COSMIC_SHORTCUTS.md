# COSMIC shortcut migration

Zenith preserves the active actions from the development machine's COSMIC
shortcut database. The graphical session implements them in Sway so the keys
remain available even when Kitty is not focused. COSMIC entries explicitly set
to `Disable` remain unassigned.

| Shortcut | Zenith action |
|---|---|
| `Super+R` | Zenith launcher overlay |
| `Super+W` | Close focused surface |
| `Super+Shift+M` | Minimize to the Sway scratchpad |
| `Super+V` | Toggle floating |
| `Super+Shift+F` | Toggle fullscreen |
| `Super+Shift+W` | Zenith surface overview |
| `Alt+Tab` | Focus next surface |
| `Alt+1` … `Alt+9` | Move focused surface to workspace 1 … 9 |
| `Alt+0` | Move focused surface to the last workspace |
| `Super+Shift+,` / `Super+Shift+.` | Move to previous / next workspace |
| `Super+Ctrl+Y` / `Super+Ctrl+Z` | Grow / shrink focused surface |
| `Ctrl+Shift+S` | Select an area and save a screenshot |
| `Super+F1` / `Super+F2` | Brightness down / up |
| `Super+F3` / `Super+F4` | Volume down / up |
| `Super+F5` | Toggle output mute |
| `Super+F6` | Toggle microphone mute |
| `Super+F7` / `Super+F8` | Next / previous media item |
| `Super+Space` | Play / pause |
| `Super+Alt+Escape` | Suspend |

Zenith additionally reserves `Super+Enter` for a new Kitty workspace and
`Super+Shift+E` for the recovery exit prompt.

Inside Kitty, `Ctrl+Shift+Enter` and `Ctrl+Shift+\` create vertical and
horizontal splits, `Ctrl+Shift+T` creates a tab, `Ctrl+Shift+Space` opens the
launcher, and `Ctrl+Shift+O` opens the surface overview.
