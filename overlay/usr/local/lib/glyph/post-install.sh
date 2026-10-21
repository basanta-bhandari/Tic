#!/usr/bin/env bash
set -euo pipefail

[[ -x /usr/bin/pacman && -d /etc ]] || {
    printf 'post-install: this script must run inside an Arch target root\n' >&2
    exit 1
}

systemctl set-default multi-user.target
systemctl enable NetworkManager.service
systemctl enable bluetooth.service
systemctl enable gpm.service
systemctl enable power-profiles-daemon.service
systemctl enable fstrim.timer
systemctl enable paccache.timer
systemctl enable systemd-timesyncd.service

# NetworkManager owns links in Glyph. Mask alternative live-image network
# managers that may otherwise race it after installation.
systemctl mask systemd-networkd.service systemd-networkd.socket
systemctl mask iwd.service

if command -v ufw >/dev/null 2>&1; then
    if ! ufw status 2>/dev/null | grep -q '^Status: active'; then
        ufw default deny incoming
        ufw default allow outgoing
        ufw --force enable
    fi
    systemctl enable ufw.service
fi

while IFS=: read -r user _ uid gid _ home shell; do
    [[ "$uid" =~ ^[0-9]+$ ]] || continue
    ((uid >= 1000 && uid < 60000)) || continue
    [[ -d "$home" ]] || continue

    usermod -s /usr/bin/fish "$user"
    cp -an /etc/skel/. "$home/"
    chown -R "$uid:$gid" "$home/.config" "$home/.tmux.conf" 2>/dev/null || true
done < /etc/passwd

usermod -s /usr/bin/fish root

while IFS=$'\t' read -r alias _; do
    [[ -n "$alias" && "$alias" != \#* ]] || continue
    [[ "$alias" =~ ^[a-z0-9][a-z0-9-]*$ ]] || continue
    ln -sfn glyph-cap "/usr/local/bin/$alias"
done </etc/glyph/capabilities.tsv

install -d -m 0755 /var/lib/glyph
printf 'installed_at=%(%Y-%m-%dT%H:%M:%SZ)T\n' -1 >/var/lib/glyph/install-state
printf 'Glyph post-install configuration complete.\n'
