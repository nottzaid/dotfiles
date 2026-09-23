#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-launcher-curate.XXXXXX")"
trap 'rm -rf -- "$TMP"' EXIT

apps="$TMP/data/applications"
stash="$TMP/state/launcher-curate/stash"
mkdir -p "$apps" "$TMP/sys/applications" "$TMP/cfg/launcher-curate"
: >"$TMP/cfg/launcher-curate/rules"
run() {
    env XDG_DATA_HOME="$TMP/data" XDG_CONFIG_HOME="$TMP/cfg" XDG_STATE_HOME="$TMP/state" \
        XDG_DATA_DIRS="$TMP/sys" HOME="$TMP" "$ROOT/files/bin/launcher-curate" "$@"
}
fail() { printf 'FAIL %s\n' "$*" >&2; exit 1; }

printf '[Desktop Entry]\nType=Application\nName=Tui\nExec=true\nTerminal=true\n' >"$apps/tui.desktop"
printf '[Desktop Entry]\nType=Application\nName=Gone\nExec=/nonexistent/bin/gone\n' >"$TMP/sys/applications/gone.desktop"
printf '[Desktop Entry]\nType=Application\nName=Fine\nExec=true\n' >"$TMP/sys/applications/fine.desktop"
cp "$apps/tui.desktop" "$TMP/tui.orig"

run >/dev/null
grep -qx 'NoDisplay=true' "$apps/tui.desktop" || fail "user terminal entry not hidden"
cmp -s "$TMP/tui.orig" "$stash/tui.desktop" || fail "user entry not stashed intact"
grep -qx 'NoDisplay=true' "$apps/gone.desktop" || fail "broken system entry not overridden"
[[ ! -e "$apps/fine.desktop" ]] || fail "working entry was touched"
[[ -z "$(run)" ]] || fail "second run is not idempotent"

printf 'show tui.desktop\nenv fine.desktop FOO=1\n' >"$TMP/cfg/launcher-curate/rules"
run >/dev/null
cmp -s "$TMP/tui.orig" "$apps/tui.desktop" || fail "user entry not restored byte-identical"
[[ ! -e "$stash/tui.desktop" ]] || fail "stash not cleaned after restore"
grep -qx 'Exec=env FOO=1 true' "$apps/fine.desktop" || fail "env repair not applied"

rm "$TMP/sys/applications/gone.desktop"
: >"$TMP/cfg/launcher-curate/rules"
run >/dev/null
[[ ! -e "$apps/gone.desktop" ]] || fail "override kept after its source was removed"
[[ ! -e "$apps/fine.desktop" ]] || fail "patch kept after its rule was removed"

printf '%s\n' 'PASS launcher-curate hides, stashes, repairs, restores, and cleans up'
