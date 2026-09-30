#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-scratch-world.XXXXXX")"
trap 'rm -rf -- "$TMP"' EXIT
STATE="$TMP/run/scratch-world"

# A fake hyprctl serving canned state and recording dispatches and evals, and
# a fake workspace-stream recording normal-world switches.
mkdir -p "$TMP/bin" "$TMP/home/.local/bin" "$TMP/run"
cat >"$TMP/bin/hyprctl" <<'EOF'
#!/usr/bin/env bash
case "$1" in
-j) cat "$FAKE/$2.json" ;;
dispatch) printf '%s\n' "$2" >>"$FAKE/log" ;;
eval) printf '%s\n' "$2" >>"$FAKE/evals" ;;
esac
EOF
cat >"$TMP/home/.local/bin/workspace-stream" <<'EOF'
#!/usr/bin/env bash
printf 'workspace-stream %s\n' "$*" >>"$FAKE/log"
EOF
chmod +x "$TMP/bin/hyprctl" "$TMP/home/.local/bin/workspace-stream"

fail() { printf 'FAIL %s\n' "$*" >&2; exit 1; }
# state FOCUSED SHOWN1 SHOWN2: HDMI-A-1 has workspaces 1-5 (3 active),
# HDMI-A-2 has 6-10 (6 active); each shows special workspace SHOWN ("" for
# none). Scratchpad workspaces 1, 2, and 4 hold windows.
state() {
    jq -n --arg f "$1" --arg s1 "$2" --arg s2 "$3" '[
        {name: "HDMI-A-1", focused: ($f == "HDMI-A-1"), activeWorkspace: {id: 3}, specialWorkspace: {name: $s1}},
        {name: "HDMI-A-2", focused: ($f == "HDMI-A-2"), activeWorkspace: {id: 6}, specialWorkspace: {name: $s2}}]' \
        >"$TMP/monitors.json"
    jq -n '[range(1; 11) | {id: ., name: tostring, monitor: (if . <= 5 then "HDMI-A-1" else "HDMI-A-2" end), windows: 0}]
        + [{id: -98, name: "special:1", monitor: "HDMI-A-1", windows: 1},
           {id: -97, name: "special:2", monitor: "HDMI-A-1", windows: 1},
           {id: -96, name: "special:4", monitor: "HDMI-A-1", windows: 2}]' >"$TMP/workspaces.json"
}
# expect "ARGS" "DISPATCHES" ["EVALS"]: run scratch-world ARGS, let a pending
# slide restore play out, and compare what it dispatched and evaluated.
expect() {
    : >"$TMP/log"
    : >"$TMP/evals"
    # shellcheck disable=SC2086
    env PATH="$TMP/bin:$PATH" HOME="$TMP/home" XDG_RUNTIME_DIR="$TMP/run" FAKE="$TMP" \
        SCRATCH_WORLD_SLIDE_SECONDS=0 "$ROOT/files/bin/scratch-world" $1
    for _ in $(seq 50); do
        [[ -e "$STATE/sideways" ]] || break
        sleep 0.05
    done
    [[ "$(cat "$TMP/log")" == "$2" ]] || fail "scratch-world $1: dispatched '$(cat "$TMP/log")', want '$2'"
    [[ "$(cat "$TMP/evals")" == "${3:-}" ]] || fail "scratch-world $1: evaluated '$(cat "$TMP/evals")', want '${3:-}'"
}
last() { cat "$STATE/last-$1"; }
toggle() { printf 'hl.dsp.workspace.toggle_special("%s")' "$1"; }
focus_monitor() { printf 'hl.dsp.focus({ monitor = "%s" })' "$1"; }
sideways="ScratchWorldSlide(\"%s\")
ScratchWorldSlide()"
right="$(printf "$sideways" right)"
left="$(printf "$sideways" left)"

# The normal world passes everything through unchanged.
state HDMI-A-1 "" ""
expect "focus 7" "workspace-stream workspace 7"
expect "focus m+1" "workspace-stream workspace m+1"
expect "move 4 --silent" 'hl.dsp.window.move({ workspace = "4", follow = false })'
expect "move m~2" 'hl.dsp.window.move({ workspace = "m~2" })'
# Each screen enters its own world: first at its lowest number, then wherever
# it last was. The bar names its screen.
expect "toggle" "$(toggle 1)"
expect "--monitor HDMI-A-2 toggle" "$(focus_monitor HDMI-A-2)
$(toggle 6)"
echo 4 >"$STATE/last-HDMI-A-1"
expect "toggle" "$(toggle 4)"
expect "send" 'hl.dsp.window.move({ workspace = "special:4", follow = false })'
expect "--monitor HDMI-A-1 focus m+1" "workspace-stream workspace m+1"

# Inside, the same keys walk this screen's scratchpad workspaces, sliding
# sideways like normal workspaces; numbers from the other screen open there.
state HDMI-A-1 "special:2" ""
expect "focus 7" "$(focus_monitor HDMI-A-2)
$(toggle 7)"
[[ "$(last HDMI-A-2)" == 7 ]] || fail "the other screen did not remember its workspace"
expect "focus 2" ""
expect "focus m+1" "$(toggle 3)" "$right"
[[ "$(last HDMI-A-1)" == 3 ]] || fail "focus did not remember the workspace"
expect "focus m-1" "$(toggle 1)" "$left"
expect "focus emptym" "$(toggle 3)" "$right"
state HDMI-A-1 "special:5" ""
expect "focus m+1" "$(toggle 1)" "$left"
state HDMI-A-1 "special:1" "special:7"
expect "focus m-1" "$(toggle 5)" "$right"
expect "focus 8" "$(focus_monitor HDMI-A-2)
$(toggle 8)" "$right"
echo 1 >"$STATE/last-HDMI-A-1"
expect "move 4 --silent" 'hl.dsp.window.move({ workspace = "special:4", follow = false })'
[[ "$(last HDMI-A-1)" == 1 ]] || fail "a silent move changed the last workspace"
expect "move m~3" 'hl.dsp.window.move({ workspace = "special:3" })' "$right"
[[ "$(last HDMI-A-1)" == 3 ]] || fail "a followed move did not remember the workspace"
expect "move m~9" ""
# Super+Shift+S sends a window home; Super+S leaves and remembers.
expect "send" 'hl.dsp.window.move({ workspace = "3", follow = false })'
expect "toggle" "$(toggle 1)"
[[ "$(last HDMI-A-1)" == 1 ]] || fail "leaving did not remember the workspace"
# Leaving right after a sideways move restores the vertical slide first.
echo pending >"$STATE/sideways"
expect "toggle" "$(toggle 1)" "ScratchWorldSlide()"

# The legacy unnamed scratchpad is not part of the world.
state HDMI-A-1 "special:special" ""
expect "focus 2" "workspace-stream workspace 2"

printf '%s\n' 'PASS scratch-world keeps a world per screen, slides like workspaces inside it, and remembers where you were'
