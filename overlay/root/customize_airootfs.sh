#!/usr/bin/env bash
set -euo pipefail

# Keep live-image customization independent of Archcraft's conventional
# Openbox/BSPWM bundles. Zenith provides the transitional Imperium session.
sed -i -E 's|^SHELL=.*|SHELL=/usr/bin/kage|' /etc/default/useradd

if ! grep -q '^\[archcraft\]$' /etc/pacman.conf; then
    cat >>/etc/pacman.conf <<'EOF'

[archcraft]
SigLevel = Optional TrustAll
Include = /etc/pacman.d/archcraft-mirrorlist
EOF
fi

install -d -m 0755 /home/liveuser
chown -R liveuser:liveuser /home/liveuser
systemctl daemon-reload || true
