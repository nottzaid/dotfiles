#!/usr/bin/env bash
# System-level configuration Home Manager cannot own. Run as root (install.sh
# --system does this through sudo). Every step is idempotent.

set -Eeuo pipefail

HERE="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
note() { printf 'system: %s\n' "$*"; }

[[ $EUID -eq 0 ]] || { note "must run as root" >&2; exit 1; }

# DNS: systemd-resolved's stub, no LLMNR (mDNS stays with Avahi).
install -Dm644 "$HERE/etc/systemd/resolved.conf.d/10-no-llmnr.conf" \
    /etc/systemd/resolved.conf.d/10-no-llmnr.conf
ln -sfn ../run/systemd/resolve/stub-resolv.conf /etc/resolv.conf

# Wi-Fi regulatory domain.
sed -i 's/^#WIRELESS_REGDOM="JO"/WIRELESS_REGDOM="JO"/' /etc/conf.d/wireless-regdom

# Unlock the login keyring with the greetd login password (SDDM's PAM stack
# already does this on Arch).
if [[ -f /etc/pam.d/greetd ]] && ! grep -q pam_gnome_keyring /etc/pam.d/greetd; then
    sed -i \
        -e '/^auth *include *system-local-login/a auth       optional     pam_gnome_keyring.so' \
        -e '/^session *include *system-local-login/a session    optional     pam_gnome_keyring.so auto_start' \
        /etc/pam.d/greetd
fi

# pacman: refuse transactions that would fill the disk.
sed -i 's/^#CheckSpace/CheckSpace/' /etc/pacman.conf

# Nix (pacman's package): flakes, parallel builds, deduplicated store.
for line in 'experimental-features = nix-command flakes' 'max-jobs = auto' 'auto-optimise-store = true'; do
    grep -qxF "$line" /etc/nix/nix.conf || printf '%s\n' "$line" >>/etc/nix/nix.conf
done

# GRUB machines: no NVMe here; single-OS, so no os-prober scan. (Limine
# machines keep their own configuration.)
if [[ -f /etc/default/grub ]] && command -v grub-mkconfig >/dev/null; then
    grub_before="$(sha256sum /etc/default/grub)"
    sed -i -e 's/ nvme_load=YES//' \
        -e "s/^GRUB_DISABLE_OS_PROBER=.*/GRUB_DISABLE_OS_PROBER='true'/" /etc/default/grub
    if [[ "$(sha256sum /etc/default/grub)" != "$grub_before" ]]; then
        grub-mkconfig -o /boot/grub/grub.cfg
    fi
fi

# Services: no boot wait for the network, bounded package cache, Nix daemon;
# Docker on demand where installed; Bluetooth only with an adapter.
systemctl disable --now NetworkManager-wait-online.service 2>/dev/null || true
systemctl enable --now paccache.timer nix-daemon.socket
if systemctl cat docker.socket >/dev/null 2>&1; then
    systemctl disable --now docker.service 2>/dev/null || true
    systemctl enable --now docker.socket
fi
if ! compgen -G "/sys/class/bluetooth/hci*" >/dev/null; then
    systemctl disable --now bluetooth.service 2>/dev/null || true
fi
systemctl restart systemd-resolved

note "applied"
