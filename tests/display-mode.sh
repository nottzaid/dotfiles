#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-display-mode.XXXXXX")"
trap 'rm -rf -- "$TMP"' EXIT
host="$ROOT/files/hosts/desktop/hypr/config/host.lua"
mode_file="$TMP/run/display-mode"

fail() { printf 'FAIL %s\n' "$*" >&2; exit 1; }

# The wiring: the key, the deployed script, and the Lua that reads the mode back.
grep -Fq 'hl.bind("SUPER + SHIFT + M", hl.dsp.exec_cmd("~/.local/bin/display-mode toggle"))' "$host" ||
    fail "host.lua does not bind Super+Shift+M to display-mode"
grep -Fq 'files/bin/display-mode' "$ROOT/hosts/desktop.nix" || fail "hosts/desktop.nix does not deploy display-mode"

# host.lua must pick the mode up from the file, and fall back to its own MODE
# for no file or a bad one. The appended assert sees the file-scope local MODE;
# a failed assert makes Hyprland reject the config.
if command -v Hyprland >/dev/null 2>&1; then
    # host_mode LINE-MODE FILE-CONTENT EXPECTED ("-" for no file)
    host_mode() {
        local tree="$TMP/hypr" file="$TMP/mode-for-host"
        rm -rf "$tree" "$file"
        cp -r "$ROOT/files/hypr" "$tree"
        cp "$ROOT/components/yt-stream-workspace/hyprland/yt-stream-workspace.lua" "$tree/"
        cp -r "$ROOT/files/hosts/desktop/hypr/." "$tree/"
        sed -i "s/^local MODE = .*/local MODE = \"$1\"/" "$tree/config/host.lua"
        printf 'assert(MODE == "%s", "MODE is " .. MODE)\n' "$3" >>"$tree/config/host.lua"
        [[ "$2" == "-" ]] || printf '%s\n' "$2" >"$file"
        DISPLAY_MODE_FILE="$file" Hyprland --verify-config --config "$tree/hyprland.lua" 2>&1 | grep -q 'config ok' ||
            fail "host.lua with MODE=$1 and file '$2' did not give $3"
    }
    host_mode extended mirror mirror
    host_mode mirror extended extended
    host_mode extended - extended
    host_mode mirror - mirror
    host_mode extended nonsense extended
fi

# A fake hyprctl serving the canned monitors, a fake reload that applies the
# recorded mode to them (or misbehaves on request), and a fake notify-send.
mkdir -p "$TMP/bin" "$TMP/run"
# Like the real one, a plain "monitors" leaves out a monitor that mirrors
# another; only "monitors all" lists it.
cat >"$TMP/bin/hyprctl" <<'EOF'
#!/usr/bin/env bash
case "$*" in
"-j monitors all") cat "$FAKE/monitors.json" ;;
"-j monitors") jq 'map(select(.mirrorOf == "none"))' "$FAKE/monitors.json" ;;
esac
exit 0
EOF
cat >"$TMP/bin/notify-send" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "${*: -1}" >>"$FAKE/notes"
EOF
cat >"$TMP/reload" <<'EOF'
#!/usr/bin/env bash
printf 'reload\n' >>"$FAKE/log"
[[ -e "$FAKE/reload-fails" ]] && exit 1
[[ -e "$FAKE/reload-ignores-mode" ]] && exit 0
jq -n --arg m "$(cat "$DISPLAY_MODE_FILE")" '
    [{name: "HDMI-A-1", mirrorOf: "none"},
     {name: "HDMI-A-2", mirrorOf: (if $m == "mirror" then "0" else "none" end)}]' >"$FAKE/monitors.json"
EOF
chmod +x "$TMP/bin/hyprctl" "$TMP/bin/notify-send" "$TMP/reload"

# layout MODE: the compositor starts in that layout.
layout() {
    jq -n --arg m "$1" '
        [{name: "HDMI-A-1", mirrorOf: "none"},
         {name: "HDMI-A-2", mirrorOf: (if $m == "mirror" then "0" else "none" end)}]' >"$TMP/monitors.json"
}
# run ARGS...: display-mode with the fakes, forgetting what the last run logged.
run() {
    : >"$TMP/log"
    : >"$TMP/notes"
    env PATH="$TMP/bin:$PATH" XDG_RUNTIME_DIR="$TMP/run" DISPLAY_MODE_FILE="$mode_file" \
        DISPLAY_MODE_RELOAD="$TMP/reload" DISPLAY_MODE_TRIES=5 FAKE="$TMP" \
        "$ROOT/files/bin/display-mode" "$@"
}
# check WHAT RELOADS NOTE: how many reloads ran and what the notification said.
check() {
    [[ "$(grep -c reload "$TMP/log" || true)" == "$2" ]] || fail "$1: $(grep -c reload "$TMP/log" || true) reloads, want $2"
    [[ "$(cat "$TMP/notes")" == "$3" ]] || fail "$1: notified '$(cat "$TMP/notes")', want '$3'"
}

layout extended
[[ "$(run status)" == extended ]] || fail "status in extended"
run
check "toggle from extended" 1 Mirror
[[ "$(cat "$mode_file")" == mirror ]] || fail "toggle from extended recorded '$(cat "$mode_file")'"
[[ "$(run status)" == mirror ]] || fail "status in mirror"

run toggle
check "toggle from mirror" 1 Extended
[[ "$(cat "$mode_file")" == extended ]] || fail "toggle from mirror recorded '$(cat "$mode_file")'"

run extended
check "extended when already extended" 0 ""
run mirror
check "mirror from extended" 1 Mirror
run mirror
check "mirror when already mirror" 0 ""

# The reload fails: the old mode stays recorded and the failure is shown.
layout extended
printf 'extended\n' >"$mode_file"
touch "$TMP/reload-fails"
if run toggle 2>/dev/null; then fail "a failed reload exited 0"; fi
check "failed reload" 1 "Could not switch to mirror"
[[ "$(cat "$mode_file")" == extended ]] || fail "a failed reload left '$(cat "$mode_file")' recorded"
rm -f "$TMP/reload-fails"

# The reload runs but the layout does not change (a host.lua that ignores the file).
touch "$TMP/reload-ignores-mode"
if run toggle 2>/dev/null; then fail "an unchanged layout exited 0"; fi
check "ignored mode" 1 "Still extended: the layout did not change"
[[ "$(cat "$mode_file")" == extended ]] || fail "an unchanged layout left '$(cat "$mode_file")' recorded"
rm -f "$TMP/reload-ignores-mode"

# A second press while a switch is running does nothing.
flock "$mode_file.lock" -c 'sleep 1' &
sleep 0.3
run toggle
check "press during a switch" 0 ""
wait

if run sideways 2>/dev/null; then fail "an unknown action exited 0"; fi

# Disconnecting the TV goes through the root helper with its one connector,
# is recorded until connected again (status says so), and a refused helper
# leaves nothing recorded. A layout asked for while it is off connects it first.
mkdir -p "$TMP/sys/class/drm/card1-HDMI-A-2" "$TMP/sys/class/drm/card1-HDMI-A-1"
echo connected >"$TMP/sys/class/drm/card1-HDMI-A-2/status"
cat >"$TMP/bin/sudo" <<'EOF'
#!/usr/bin/env bash
[[ $1 == -n ]] && shift
printf 'helper %s\n' "${*:2}" >>"$FAKE/log"
[[ ! -e "$FAKE/helper-fails" ]]
EOF
chmod +x "$TMP/bin/sudo"
link() { DISPLAY_MODE_SYS="$TMP/sys" DISPLAY_MODE_LINK="$TMP/run/display-link" DISPLAY_MODE_HELPER=/x/helper run "$@"; }
layout extended
link off
[[ "$(grep helper "$TMP/log")" == "helper off card1-HDMI-A-2" ]] || fail "off ran: $(cat "$TMP/log")"
check "off" 0 "TV disconnected"
[[ "$(link status)" == off ]] || fail "status while disconnected is $(link status)"
link off
check "off when off" 0 ""
link link
[[ "$(grep helper "$TMP/log")" == "helper detect card1-HDMI-A-2" ]] || fail "link while off ran: $(cat "$TMP/log")"
check "link while off" 0 "TV connected"
[[ "$(link status)" == extended ]] || fail "status after connecting is $(link status)"
touch "$TMP/helper-fails"
if link off 2>/dev/null; then fail "a refused helper exited 0"; fi
[[ "$(link status)" == extended ]] || fail "a refused disconnect left it recorded off"
rm -f "$TMP/helper-fails"
link off
link mirror
[[ "$(grep -c 'helper detect' "$TMP/log")" == 1 && "$(link status)" == mirror ]] ||
    fail "mirror while off did not connect first: $(cat "$TMP/log")"
# While it is off, the layout it comes back in can be recorded without
# connecting it, printing the one recorded before (host.lua's own with none).
# While it is connected, record changes nothing.
rc=0
link record extended >/dev/null || rc=$?
[[ $rc == 3 && "$(cat "$mode_file")" == mirror ]] || fail "record while connected: exit $rc, recorded $(cat "$mode_file")"
link off
[[ "$(link record extended)" == mirror && "$(cat "$mode_file")" == extended ]] ||
    fail "record while off recorded $(cat "$mode_file")"
[[ -z "$(grep helper "$TMP/log")" && "$(link status)" == off ]] || fail "record connected the TV: $(cat "$TMP/log")"
rm -f "$mode_file"
[[ "$(link record mirror)" == extended ]] || fail "with nothing recorded, record did not print host.lua's default"
if link record sideways 2>/dev/null; then fail "an unknown layout was recorded"; fi
link on
jq -n '[{name: "HDMI-A-1", mirrorOf: "none"}]' >"$TMP/monitors.json"
[[ "$(link status)" == none ]] || fail "status with no TV attached is $(link status)"
[[ "$(link record extended)" == mirror && "$(cat "$mode_file")" == extended ]] ||
    fail "record with no TV attached recorded $(cat "$mode_file")"

printf '%s\n' 'PASS display-mode toggles mirror and extended through host.lua, recovers from a failed reload, ignores presses during a switch, disconnects and connects the TV, and records the layout it comes back in'
