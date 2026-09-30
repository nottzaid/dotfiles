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
# state FOCUSED ACTIVE1 ACTIVE2 [HIDDEN_ON_2]: HDMI-A-1 has workspaces 1-5,
# HDMI-A-2 6-10; each shows workspace ACTIVE (-1337 is the named "gaming").
# HDMI-A-1's hidden 101, 102, and 104 hold windows; HIDDEN_ON_2 lists more
# of its hidden ids, left on HDMI-A-2 as after a replug.
state() {
    jq -n --arg f "$1" --argjson a1 "$2" --argjson a2 "$3" '
        def ws($id): {id: $id, name: (if $id < 0 then "gaming" else ($id | tostring) end)};
        [{name: "HDMI-A-1", focused: ($f == "HDMI-A-1"), activeWorkspace: ws($a1)},
         {name: "HDMI-A-2", focused: ($f == "HDMI-A-2"), activeWorkspace: ws($a2)}]' >"$TMP/monitors.json"
    jq -n --argjson a1 "$2" --argjson a2 "$3" --argjson moved "[${4:-}]" '
        [range(1; 11) | {id: ., monitor: (if . <= 5 then "HDMI-A-1" else "HDMI-A-2" end), windows: 0}]
        + [{id: 101, windows: 1}, {id: 102, windows: 1}, {id: 104, windows: 2}, {id: $a1, windows: 0}]
          | map(.monitor //= "HDMI-A-1")
        + [{id: $a2, monitor: "HDMI-A-2", windows: 0}]
        + ($moved | map({id: ., monitor: "HDMI-A-2", windows: 1}))
        | unique_by(.id)' >"$TMP/workspaces.json"
}
# expect "ARGS" "DISPATCHES" ["EVALS"]: run scratch-world ARGS, let a pending
# slide restore play out, and compare what it dispatched and evaluated.
expect() {
    : >"$TMP/log"
    : >"$TMP/evals"
    # shellcheck disable=SC2086
    env PATH="$TMP/bin:$PATH" HOME="$TMP/home" XDG_RUNTIME_DIR="$TMP/run" XDG_STATE_HOME="$TMP/state" \
        FAKE="$TMP" SCRATCH_WORLD_SLIDE_SECONDS=0 "$ROOT/files/bin/scratch-world" $1
    for _ in $(seq 50); do
        [[ -e "$STATE/vertical" ]] || break
        sleep 0.05
    done
    [[ "$(cat "$TMP/log")" == "$2" ]] || fail "scratch-world $1: dispatched '$(cat "$TMP/log")', want '$2'"
    [[ "$(cat "$TMP/evals")" == "${3:-}" ]] || fail "scratch-world $1: evaluated '$(cat "$TMP/evals")', want '${3:-}'"
}
recalled() { cat "$STATE/$1-$2"; }
go() { printf 'hl.dsp.focus({ workspace = "%s" })' "$1"; }
focus_monitor() { printf 'hl.dsp.focus({ monitor = "%s" })' "$1"; }
slide() { printf 'ScratchWorldSlide("%s")\nScratchWorldSlide()' "$1"; }

# The normal world works as before, but steps over the hidden workspaces
# (101-104 sit on HDMI-A-1 too).
state HDMI-A-1 3 6
expect "focus 7" "workspace-stream workspace 7"
expect "focus m+1" "workspace-stream workspace 4"
expect "focus m-1" "workspace-stream workspace 2"
expect "focus emptym" "workspace-stream workspace emptym"
expect "move 4 --silent" 'hl.dsp.window.move({ workspace = "4", follow = false })'
expect "move m~2" 'hl.dsp.window.move({ workspace = "2" })'
state HDMI-A-1 5 6
expect "focus m+1" "workspace-stream workspace 1"

# Each screen enters its own world, sliding down: first at 1 of its own
# block, then wherever it last was. The bar names its screen.
state HDMI-A-1 3 6
expect "toggle" "$(go 101)" "$(slide top)"
[[ "$(recalled normal HDMI-A-1)" == 3 ]] || fail "entering did not remember the normal workspace"
expect "--monitor HDMI-A-2 toggle" "$(focus_monitor HDMI-A-2)
$(go 201)" "$(slide top)"
[[ "$(cat "$TMP/state/scratch-world/bases")" == "HDMI-A-1 100
HDMI-A-2 200" ]] || fail "screens did not get their own blocks"
echo 4 >"$STATE/last-HDMI-A-1"
expect "toggle" "$(go 104)" "$(slide top)"
expect "send" 'hl.dsp.window.move({ workspace = "104", follow = false })'

# Inside, the same keys walk this screen's 1-10 with the normal slide.
state HDMI-A-1 102 6
expect "focus 7" "$(go 107)"
[[ "$(recalled last HDMI-A-1)" == 7 ]] || fail "focus did not remember the workspace"
expect "focus 2" ""
expect "focus 11" ""
expect "focus m+1" "$(go 103)"
expect "focus m-1" "$(go 101)"
expect "focus emptym" "$(go 103)"
state HDMI-A-1 110 6
expect "focus m+1" "$(go 101)"
state HDMI-A-1 101 6
expect "focus m-1" "$(go 110)"
# A move right after entering puts the normal slide back first.
echo pending >"$STATE/vertical"
expect "focus 3" "$(go 103)" "ScratchWorldSlide()"
echo 1 >"$STATE/last-HDMI-A-1"
expect "move 4 --silent" 'hl.dsp.window.move({ workspace = "104", follow = false })'
[[ "$(recalled last HDMI-A-1)" == 1 ]] || fail "a silent move changed the last workspace"
expect "move m~3" 'hl.dsp.window.move({ workspace = "103" })'
[[ "$(recalled last HDMI-A-1)" == 3 ]] || fail "a followed move did not remember the workspace"
expect "move 11" ""
# Super+Shift+S sends a window home; Super+S leaves, sliding up, and remembers.
expect "send" 'hl.dsp.window.move({ workspace = "3", follow = false })'
expect "toggle" "workspace-stream workspace 3" "$(slide bottom)"
[[ "$(recalled last HDMI-A-1)" == 1 ]] || fail "leaving did not remember the workspace"
# After replugging, the screen's hidden workspace is brought back to it.
state HDMI-A-1 101 6 105
expect "focus 5" 'hl.dsp.workspace.move({ workspace = "105", monitor = "HDMI-A-1" })
'"$(go 105)"

# Named normal workspaces are remembered by name.
state HDMI-A-1 -1337 6
echo 1 >"$STATE/last-HDMI-A-1"
expect "toggle" "$(go 101)" "$(slide top)"
state HDMI-A-1 101 6
expect "toggle" "workspace-stream workspace name:gaming" "$(slide bottom)"

printf '%s\n' 'PASS scratch-world keeps a hidden 1-10 per screen, slides vertically only in and out, and remembers where you were'
