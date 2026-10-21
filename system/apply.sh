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

# zram swap: a disk behind it, for what sits untouched in it
# (libexec/zram-writeback). A zram swap set up without one is set up again
# now if what it holds fits in free RAM (taking it off swap reads it all
# back), else it gets one at the next boot.
install -Dm755 "$HERE/libexec/zram-writeback" /usr/local/libexec/zram-writeback
install -Dm644 "$HERE/etc/systemd/system/systemd-zram-setup@.service.d/writeback.conf" \
    /etc/systemd/system/systemd-zram-setup@.service.d/writeback.conf
systemctl daemon-reload
for sys in /sys/block/zram*; do
    [[ -e $sys/backing_dev && $(<"$sys/backing_dev") == none ]] || continue
    dev=${sys##*/}
    used=$(awk -v d="/dev/$dev" '$1 == d {print $4}' /proc/swaps) # KiB
    [[ -n $used ]] || continue
    if ((used + 1048576 < $(awk '/^MemAvailable:/ {print $2}' /proc/meminfo))); then
        # (zram-generator's reset right after swapoff can find the device
        # still open by udev's probe, and fail: reset it here until it takes.)
        systemctl stop "dev-$dev.swap" "systemd-zram-setup@$dev.service" || true
        udevadm settle || true
        for _ in $(seq 1 50); do
            [[ $(<"$sys/initstate") == 0 ]] && break
            echo 1 >"$sys/reset" 2>/dev/null || sleep 0.1
        done
        systemctl reset-failed "systemd-zram-setup@$dev.service" 2>/dev/null || true
        if systemctl start "dev-$dev.swap" && [[ $(<"$sys/backing_dev") != none ]]; then
            note "$dev: $(<"$sys/backing_dev") behind it"
        elif swapon --show=NAME --noheadings | grep -qx "/dev/$dev"; then
            note "$dev: swap again, but no disk behind it: see journalctl -u systemd-zram-setup@$dev"
        else
            # (Never left without swap: the device as it was, if it still is.)
            swapon -p 100 "/dev/$dev" 2>/dev/null || true
            note "$dev: could not be set up again ($(swapon --show=NAME --noheadings | grep -qx "/dev/$dev" && echo "swap as before" || echo "NO SWAP until the next boot")): see systemctl status systemd-zram-setup@$dev"
        fi
    else
        note "$dev: holds too much to set up again now; a disk behind it at the next boot"
    fi
done

# Gaming mode: the helpers that disconnect the other screens and move cold
# swap to disk, runnable without a password (files/bin/gaming-mode).
install -Dm755 "$HERE/libexec/gaming-mode-display" /usr/local/libexec/gaming-mode-display
install -Dm440 "$HERE/etc/sudoers.d/gaming-mode" /etc/sudoers.d/gaming-mode
visudo -cf /etc/sudoers.d/gaming-mode >/dev/null

# ZhiXu gamepad: keep it connected and its stick and D-pad unswapped. Last,
# because it refuses to run over the old patched xpad.
"$HERE/../components/linux-zhixu-controller-fix/install.sh"

note "applied"
