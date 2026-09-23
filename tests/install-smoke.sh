#!/usr/bin/env bash

set -Eeuo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
TEST_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-install.XXXXXX")"
TEST_HOME="$TEST_ROOT/home"

cleanup() {
    rm -rf -- "$TEST_ROOT"
}
trap cleanup EXIT

mkdir -p "$TEST_HOME"

export HOME="$TEST_HOME"
export XDG_CACHE_HOME="$TEST_HOME/.cache"
export XDG_CONFIG_HOME="$TEST_HOME/.config"
export XDG_DATA_HOME="$TEST_HOME/.local/share"
export XDG_STATE_HOME="$TEST_HOME/.local/state"
export DOTFILES_SKIP_HM=1
export DOTFILES_SKIP_SESSION_IMPORT=1
export DOTFILES_SKIP_PACKAGE_INSTALL=1
unset HYPRLAND_INSTANCE_SIGNATURE

# Dotfiles themselves are owned by `home-manager switch --flake "$ROOT"`
# on a real home (skipped here); this exercises the provisioning modes.
"$ROOT/install.sh" --streaming
"$ROOT/verify.sh"

[[ ! -L "$HOME/.config/yt-stream-workspace/config" ]]
[[ "$(stat -c %a "$HOME/.config/yt-stream-workspace/config")" == 600 ]]
# Match the literal runtime expression copied from the component template.
# shellcheck disable=SC2016
grep -Fqx 'YTWS_WALLPAPER="$HOME/Pictures/background.jpg"' \
    "$HOME/.config/yt-stream-workspace/config"
printf '\n# preserved user edit\n' >>"$HOME/.config/yt-stream-workspace/config"

"$ROOT/install.sh" --streaming
"$ROOT/verify.sh"

grep -q '^# preserved user edit$' "$HOME/.config/yt-stream-workspace/config"

printf 'PASS isolated provisioning, idempotent rerun, and verification\n'
