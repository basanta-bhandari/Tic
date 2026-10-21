#!/usr/bin/env bash
set -euo pipefail

[[ $# -eq 2 ]] || { printf 'Usage: check-profile.sh PROFILE FLAVOR\n' >&2; exit 2; }
profile="$1"
flavor="$2"

[[ -x "$profile/airootfs/usr/local/bin/glyph" ]]
[[ -x "$profile/airootfs/usr/local/bin/glyph-deploy" ]]
[[ -x "$profile/airootfs/usr/local/bin/tac" ]]
[[ -L "$profile/airootfs/usr/local/bin/file-manager-1" ]]
[[ "$(readlink "$profile/airootfs/usr/local/bin/file-manager-1")" == glyph-cap ]]
[[ -s "$profile/airootfs/root/.newsboat/urls" ]]
[[ -r "$profile/airootfs/root/.config/nvim/init.lua" ]]
[[ -r "$profile/airootfs/root/.config/yazi/yazi.toml" ]]
[[ -r "$profile/airootfs/root/.tmux.conf" ]]
[[ -r "$profile/airootfs/usr/local/share/glyph/packages.x86_64" ]]
[[ -r "$profile/airootfs/usr/local/share/glyph/docs/LINUXLINKS_TUI_100.md" ]]
[[ "$(<"$profile/airootfs/usr/local/share/glyph/flavor")" == "$flavor" ]]
grep -q '^iso_name="glyph-linux"$' "$profile/profiledef.sh"
grep -q '^fish$' "$profile/packages.x86_64"
grep -q '^networkmanager$' "$profile/packages.x86_64"
grep -q '^base$' "$profile/packages.x86_64"

case "$flavor" in
    core)
        ! grep -q '^visidata$' "$profile/packages.x86_64"
        ;;
    full|dev)
        grep -q '^visidata$' "$profile/packages.x86_64"
        ;;
esac

printf 'Prepared %s profile passed composition checks.\n' "$flavor"
