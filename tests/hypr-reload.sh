#!/usr/bin/env bash

set -Eeuo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-hypr-reload.XXXXXX")"
trap 'rm -rf -- "$TMP"' EXIT
# host.lua reads the mode display-mode recorded this login; the mode loop below
# must test the MODE line, not whatever Super+Shift+M last set.
export DISPLAY_MODE_FILE="$TMP/no-recorded-mode"
command -v Hyprland >/dev/null 2>&1 || { printf 'SKIP no Hyprland\n'; exit 0; }

# A machine's Hyprland config in a scratch home: the shared tree, plus its
# host.lua, which hyprland.lua loads from $HOME.
assemble() {
    rm -rf "${TMP:?}/home"
    mkdir -p "$TMP/home/.config"
    cp -r "$ROOT/home/.config/hypr" "$TMP/home/.config/hypr"
    cp "$ROOT/hosts/$1/.config/hypr/host.lua" "$TMP/home/.config/hypr/"
}
verify_tree() {
    HOME="$TMP/home" Hyprland --verify-config --config "$TMP/home/.config/hypr/hyprland.lua" 2>&1 | grep -q 'config ok'
}

for host_dir in "$ROOT"/hosts/*/; do
    host="$(basename "$host_dir")"
    assemble "$host"
    verify_tree || { printf 'Hyprland config for %s is invalid\n' "$host" >&2; exit 1; }
done
# Both desktop monitor modes must produce a valid config, whichever is selected.
for mode in mirror extended; do
    assemble desktop
    sed -i "s/^local MODE = .*/local MODE = \"$mode\"/" "$TMP/home/.config/hypr/host.lua"
    verify_tree || { printf 'desktop MODE=%s does not produce a valid config\n' "$mode" >&2; exit 1; }
done
printf '%s\n' 'PASS Hyprland config for every machine and both desktop display modes'
