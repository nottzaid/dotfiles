#!/usr/bin/env bash

set -Eeuo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
BOX_NAME="${DOTFILES_TEST_BOX:-dotfiles-test-$UID-$$}"
BOX_IMAGE="${DOTFILES_TEST_IMAGE:-docker.io/library/archlinux:latest}"
BOX_HOME="$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-distrobox.XXXXXX")"

cleanup() {
    distrobox rm --force "$BOX_NAME" >/dev/null 2>&1 || true
    find "$BOX_HOME" -depth -delete 2>/dev/null || true
}
trap cleanup EXIT

command -v distrobox >/dev/null 2>&1 || {
    printf '%s\n' 'distrobox is required' >&2
    exit 1
}
command -v podman >/dev/null 2>&1 || {
    printf '%s\n' 'podman is required' >&2
    exit 1
}

if distrobox list 2>/dev/null | awk 'NR > 1 {print $3}' |
    grep -Fxq "$BOX_NAME"; then
    printf 'Distrobox already exists: %s\n' "$BOX_NAME" >&2
    exit 1
fi

distrobox create --yes \
    --name "$BOX_NAME" \
    --image "$BOX_IMAGE" \
    --home "$BOX_HOME" \
    --volume "$ROOT:/opt/dotfiles:ro"

# This program is expanded inside the container, not by the host shell.
# shellcheck disable=SC2016
distrobox enter "$BOX_NAME" -- bash -lc '
    set -Eeuo pipefail
    # Hermetic boundary: distrobox forwards the host environment (notably
    # PATH); scrub it to container system dirs only.
    export PATH=/usr/local/sbin:/usr/local/bin:/usr/bin:/bin
    sudo pacman -Syu --needed --noconfirm \
        git nodejs openssl pnpm power-profiles-daemon python python-gobject uv
    cp -a /opt/dotfiles "$HOME/dotfiles"
    cd "$HOME/dotfiles"
    # NB: tests/bash-startup.sh is intentionally absent here: it asserts the
    # live Home Manager session PATH, which cannot exist in a clean image
    # without nix. It runs on switched machines instead.
    ./tests/install-smoke.sh

'

printf '%s\n' 'PASS disposable Arch Distrobox workstation restore'
