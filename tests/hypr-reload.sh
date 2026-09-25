#!/usr/bin/env bash

set -Eeuo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-hypr-reload.XXXXXX")"
trap 'rm -rf -- "$TMP"' EXIT

config="$ROOT/files/hypr/hyprland.lua"
monitors="$ROOT/files/hosts/desktop/hypr/config/host.lua"
rules="$ROOT/files/hypr/config/windowrules.lua"

# A machine's Hyprland tree: the shared files plus files/hosts/<host>/hypr.
assemble() {
    rm -rf "$TMP/hypr"
    cp -r "$ROOT/files/hypr" "$TMP/hypr"
    cp -r "$ROOT/files/hosts/$1/hypr/." "$TMP/hypr/"
}
verify_tree() {
    command -v Hyprland >/dev/null 2>&1 || return 0
    Hyprland --verify-config --config "$TMP/hypr/hyprland.lua" 2>&1 | grep -q 'config ok'
}

grep -Fq 'require("config.windowrules")' "$config"
grep -Fq 'require("config.host")' "$config"
grep -Fq 'require("yt-stream-workspace")' "$config"
for host_dir in "$ROOT"/files/hosts/*/; do
    host="$(basename "$host_dir")"
    [[ -f "$host_dir/hypr/config/host.lua" ]] || { printf '%s has no hypr/config/host.lua\n' "$host" >&2; exit 1; }
    assemble "$host"
    verify_tree || { printf 'Hyprland config for %s is invalid\n' "$host" >&2; exit 1; }
done
# Both desktop monitor modes must produce a valid config, whichever is selected.
grep -Eq '^local MODE = "(mirror|extended)"$' "$monitors"
for mode in mirror extended; do
    assemble desktop
    sed -i "s/^local MODE = .*/local MODE = \"$mode\"/" "$TMP/hypr/config/host.lua"
    verify_tree || { printf 'desktop MODE=%s does not produce a valid config\n' "$mode" >&2; exit 1; }
done
grep -Fq 'name = "swash-overlay"' "$rules"
grep -Fq 'fullscreen_state = 2' "$rules"
grep -Fq 'sync_fullscreen = true' "$rules"
if sed -n '/name = "swash-overlay"/,/^})/p' "$rules" | grep -Fq 'no_anim'; then
    printf '%s\n' 'Swash animation is unexpectedly disabled' >&2
    exit 1
fi

bash -n "$ROOT/files/bin/swash-screenshot"
grep -Fq '$HOME/.local/bin/swash-screenshot' "$ROOT/files/noctalia.toml"

printf '%s\n' 'PASS current Hyprland, Noctalia, and animated Swash integration'
