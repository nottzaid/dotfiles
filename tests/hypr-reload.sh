#!/usr/bin/env bash

set -Eeuo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-hypr-reload.XXXXXX")"
trap 'rm -rf -- "$TMP"' EXIT

config="$ROOT/files/hypr/hyprland.lua"
monitors="$ROOT/files/hypr/config/monitors.lua"
rules="$ROOT/files/hypr/config/windowrules.lua"

grep -Fq 'require("config.windowrules")' "$config"
grep -Fq 'require("yt-stream-workspace")' "$config"
# Both monitor modes must produce a valid config, whichever one is selected.
grep -Eq '^local MODE = "(mirror|extended)"$' "$monitors"
for mode in mirror extended; do
    rm -rf "$TMP/hypr"
    cp -r "$ROOT/files/hypr" "$TMP/hypr"
    sed -i "s/^local MODE = .*/local MODE = \"$mode\"/" "$TMP/hypr/config/monitors.lua"
    if command -v Hyprland >/dev/null 2>&1 &&
        ! Hyprland --verify-config --config "$TMP/hypr/hyprland.lua" 2>&1 | grep -q 'config ok'; then
        printf 'monitors.lua MODE=%s does not produce a valid config\n' "$mode" >&2
        exit 1
    fi
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
