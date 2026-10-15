#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-gaming-mode.XXXXXX")"
trap 'rm -rf -- "$TMP"' EXIT
script="$ROOT/files/bin/gaming-mode"
helper="$ROOT/system/libexec/gaming-mode-display"

fail() { printf 'FAIL %s\n' "$*" >&2; exit 1; }

# The wiring: the deployed script, the hook that runs it, the root helper and
# the sudoers rule that lets it run without a password.
grep -Fq 'files/bin/gaming-mode' "$ROOT/modules/tools.nix" || fail "modules/tools.nix does not deploy gaming-mode"
grep -Fq 'require("config.gaming")' "$ROOT/files/hypr/hyprland.lua" || fail "hyprland.lua does not load config.gaming"
grep -Fq 'hl.exec_cmd("~/.local/bin/gaming-mode sync")' "$ROOT/files/hypr/config/gaming.lua" ||
    fail "gaming.lua does not run gaming-mode sync"
grep -Fq 'gaming-mode-display' "$ROOT/system/apply.sh" || fail "system/apply.sh does not install the display helper"
grep -Fxq '%wheel ALL=(root) NOPASSWD: /usr/local/libexec/gaming-mode-display' "$ROOT/system/etc/sudoers.d/gaming-mode" ||
    fail "the sudoers rule names something other than the helper"

# The helper runs as root: it must refuse anything but off|detect and a DRM
# connector name, before touching sysfs.
for args in "" "on card1-HDMI-A-1" "off HDMI-A-1" "off card1-../../power/state" "detect card1-a/b"; do
    # shellcheck disable=SC2086 # the words are the arguments
    if sh "$helper" $args >/dev/null 2>&1; then fail "the display helper accepted '$args'"; fi
done

export XDG_RUNTIME_DIR="$TMP/run"
mkdir -p "$XDG_RUNTIME_DIR"
[[ "$(bash "$script" status)" == off ]] || fail "status without state is not 'off'"
if bash "$script" bogus 2>/dev/null; then fail "an unknown command was accepted"; fi

# Replaying a stopped process: the same directory, environment and arguments
# whatever they contain, Hyprland's launch tokens from the new launch only.
sed '/^# --- main/,$d' "$script" >"$TMP/functions.sh"
# shellcheck source=/dev/null
source "$TMP/functions.sh"
rec="$TMP/record"
mkdir -p "$rec" "$TMP/a dir"
printf '%s\0' "PATH=$PATH" 'ODD=a b "c" $d `e`' HL_EXEC_RULE_TOKEN=stale >"$rec/environ"
# shellcheck disable=SC2016 # expanded by the replayed shell
printf '%s\0' bash -c 'printf "%s\n" "$PWD" "$ODD" "${HL_EXEC_RULE_TOKEN-unset}" "$@"' argv0 'x y' ']==]' "'" >"$rec/cmdline"
echo "$TMP/a dir" >"$rec/cwd"
echo "/user.slice/x.service" >"$rec/cgroup"
expected="$(printf '%s\n' "$TMP/a dir" 'a b "c" $d `e`' fresh 'x y' ']==]' "'" extra)"
[[ "$(HL_EXEC_RULE_TOKEN=fresh sh -c "$(replay_cmd "$rec" extra)")" == "$expected" ]] ||
    fail "a replay did not reproduce the process"
[[ "$(env -u HL_EXEC_RULE_TOKEN sh -c "$(replay_cmd "$rec")" | sed -n 3p)" == unset ]] ||
    fail "a replay passed on a stale launch token"

# A process with its own scope in the apps gets a new scope like it.
echo "$USER_CG/app.slice/app-graphical.slice/app-Hyprland-kitty-3862fb78.scope" >"$rec/cgroup"
[[ "$(replay_cmd "$rec")" =~ systemd-run\ --user\ --scope\ --quiet\ --slice=app-graphical\.slice\ --unit=app-Hyprland-kitty-[0-9a-f]{8}\.scope\ -- ]] ||
    fail "a replay did not recreate the app scope"

# Freezing is recursive: a cgroup covers itself and everything below it, and
# nothing beside it that merely shares a prefix.
covers /a/b.slice $'/x\n/a/b.slice/c.scope' || fail "a slice does not cover a scope in it"
covers /a/b.scope $'/a/b.scope' || fail "a cgroup does not cover itself"
if covers /a/b $'/a/bc.scope\n'; then fail "a cgroup covers a sibling with a longer name"; fi
if covers /a/b ""; then fail "a cgroup covers an empty list"; fi
printf '%s\n' one two three >"$TMP/lines"
drop_line "$TMP/lines" two
[[ "$(cat "$TMP/lines")" == $'one\nthree' ]] || fail "drop_line removed the wrong lines"
drop_line "$TMP/lines" one
drop_line "$TMP/lines" three
[[ ! -e "$TMP/lines" ]] || fail "drop_line left an empty record"

# A process is named by pid and start time: a pid alone may be reused.
sleep 30 &
sleeper=$!
start=$(starttime_of "$sleeper")
same_process "$sleeper" "$start" || fail "a running process is not itself"
if same_process "$sleeper" "$((start + 1))"; then fail "a different start time matched"; fi
kill "$sleeper"
wait "$sleeper" 2>/dev/null || true
if same_process "$sleeper" "$start"; then fail "an ended process still matched"; fi

# A restored process is found by its whole command line, byte for byte,
# started since it was stopped and not already counted by another restore.
CLAIMED="$TMP/claimed"
sh -c 'sleep 30; :' argv0 'a b' '' x &
target=$!
for _ in $(seq 1 50); do [[ "$(tr '\0' ' ' <"/proc/$target/cmdline")" == *x* ]] && break; sleep 0.1; done
printf '%s\0' sh -c 'sleep 30; :' argv0 'a b' '' x >"$TMP/want"
running_like "$TMP/want" 0 && [[ $RUNNING_PID == "$target" ]] || fail "a running process was not found by its command line"
if running_like "$TMP/want" 0; then fail "a claimed process was found again"; fi
: >"$CLAIMED"
if running_like "$TMP/want" "$(($(starttime_of "$target") + 1))"; then fail "a process older than the stop matched"; fi
printf '%s\0' sh -c 'sleep 30; :' argv0 'a b' >"$TMP/want"
if running_like "$TMP/want" 0; then fail "a prefix of a command line matched"; fi
printf '%s\0' sh -c 'sleep 30; :' argv0 'a b' '' y >"$TMP/want"
if running_like "$TMP/want" 0; then fail "a different last argument matched"; fi
: >"$TMP/want"
if running_like "$TMP/want" 0; then fail "an empty command line matched (kernel threads have one)"; fi
kill "$target"
wait "$target" 2>/dev/null || true

# Reclaiming a frozen cgroup runs in the background at idle priority and
# stops once the cgroup is thawed.
cg="$TMP/cg"
mkdir -p "$cg"
echo 1 >"$cg/cgroup.freeze"
: >"$cg/memory.reclaim"
reclaim_cold "$cg"
reclaimer=$!
# (Read until seen: each step rewrites the file, so a read may meet it empty.)
seen=""
for _ in $(seq 1 50); do [[ "$(<"$cg/memory.reclaim")" == 32M ]] && seen=1 && break; sleep 0.1; done
[[ -n $seen ]] || { kill "$reclaimer" 2>/dev/null; fail "the frozen cgroup was not reclaimed in steps"; }
[[ "$(chrt -p "$reclaimer" 2>/dev/null)" == *SCHED_IDLE* ]] || fail "the reclaim does not run at idle priority"
echo 0 >"$cg/cgroup.freeze"
for _ in $(seq 1 50); do kill -0 "$reclaimer" 2>/dev/null || break; sleep 0.1; done
if kill -0 "$reclaimer" 2>/dev/null; then
    kill "$reclaimer"
    fail "the reclaim went on after the thaw"
fi

# The dispatch Hyprland gets must read back as the same command and rules,
# whatever closing brackets the command holds.
if command -v lua >/dev/null 2>&1; then
    hyprctl() { printf '%s' "$2" >"$TMP/dispatch"; }
    cmd='echo "]==]" ]===] done'
    compositor_exec "$cmd" 'workspace = "name:x silent", no_initial_focus = true'
    got="$(lua -e "hl = { dsp = { exec_cmd = function(c, r) io.write(c, '|', r.workspace, '|', tostring(r.no_initial_focus)) end } }
        $(<"$TMP/dispatch")")"
    [[ "$got" == "$cmd|name:x silent|true" ]] || fail "the dispatch reads back as: $got"
fi

# Sound reaches a screen through any route: here the game plays through an
# effects sink (two nodes sharing a link group) into the GPU's HDMI card,
# while the default sink is the motherboard's analog card. A card counts as a
# screen's only when it sits on a GPU (connector entries are not GPUs).
SYS="$TMP/sys"
mkdir -p "$SYS/devices/0000:01:00.0/drm/card1" "$SYS/devices/0000:01:00.1" "$SYS/devices/0000:00:1b.0" \
    "$SYS/class/drm/card1" "$SYS/class/drm/card1-HDMI-A-2" "$SYS/class/sound/card0" "$SYS/class/sound/card1"
ln -s "$SYS/devices/0000:01:00.0" "$SYS/class/drm/card1/device"
ln -s "$SYS/devices/0000:01:00.0/drm/card1" "$SYS/class/drm/card1-HDMI-A-2/device"
ln -s "$SYS/devices/0000:00:1b.0" "$SYS/class/sound/card0/device"
ln -s "$SYS/devices/0000:01:00.1" "$SYS/class/sound/card1/device"
pw-dump() {
    cat <<'EOF'
[{"id": 30, "type": "PipeWire:Interface:Client", "info": {"props": {"application.process.id": 4242}}},
 {"id": 31, "type": "PipeWire:Interface:Node", "info": {"props": {"client.id": 30, "media.class": "Stream/Output/Audio"}}},
 {"id": 40, "type": "PipeWire:Interface:Node", "info": {"props": {"media.class": "Audio/Sink", "node.name": "eq_in", "node.link-group": "eq"}}},
 {"id": 41, "type": "PipeWire:Interface:Node", "info": {"props": {"media.class": "Stream/Output/Audio", "node.name": "eq_out", "node.link-group": "eq"}}},
 {"id": 50, "type": "PipeWire:Interface:Node", "info": {"props": {"media.class": "Audio/Sink", "device.api": "alsa", "alsa.card": "1", "alsa.name": "MONITOR", "node.name": "hdmi"}}},
 {"id": 52, "type": "PipeWire:Interface:Node", "info": {"props": {"media.class": "Audio/Sink", "device.api": "alsa", "alsa.card": "0", "alsa.name": "ALC1150 Analog", "node.name": "analog"}}},
 {"id": 60, "type": "PipeWire:Interface:Link", "info": {"output-node-id": 31, "input-node-id": 40}},
 {"id": 61, "type": "PipeWire:Interface:Link", "info": {"output-node-id": 41, "input-node-id": 50}},
 {"id": 70, "type": "PipeWire:Interface:Metadata", "props": {"metadata.name": "default"},
  "metadata": [{"subject": 0, "key": "default.audio.sink", "value": {"name": "analog"}}]}]
EOF
}
# shellcheck disable=SC2034 # read by audio_screens
PROTECTED=4242
[[ "$(audio_screens)" == MONITOR ]] || fail "the game's sound through an effects sink did not reach the HDMI screen"
# shellcheck disable=SC2034 # read by audio_screens
PROTECTED=""
got="$(audio_screens)" || fail "an analog-only route read as a failure"
[[ -z "$got" ]] || fail "analog-only sound was put on a screen: $got"

# A screen that mirrors the game's screen shows the game: it stays on. Any
# other screen goes off.
echo connected >"$SYS/class/drm/card1-HDMI-A-2/status"
mkdir -p "$SYS/class/drm/card1-DP-1"
echo connected >"$SYS/class/drm/card1-DP-1/status"
# shellcheck disable=SC2034 # read by disconnect_displays
DISPLAY_HELPER=/x/helper DISPLAYS="$TMP/displays" LOG="$TMP/log" GAMING_WS=gaming
: >"$TMP/helper-calls"
sudo() { [[ $1 == -n && $2 == -l ]] && return 0; shift; echo "$*" >>"$TMP/helper-calls"; }
hyprctl() {
    [[ "$*" == "-j monitors all" ]] || return 1
    cat <<'EOF'
[{"id": 1, "name": "HDMI-A-2", "model": "MONITOR", "disabled": false, "mirrorOf": "0", "activeWorkspace": {"name": "gaming"}},
 {"id": 0, "name": "HDMI-A-1", "model": "C24F390", "disabled": false, "mirrorOf": "none", "activeWorkspace": {"name": "gaming"}},
 {"id": 2, "name": "DP-1", "model": "OTHER", "disabled": false, "mirrorOf": "none", "activeWorkspace": {"name": "3"}}]
EOF
}
disconnect_displays
[[ "$(<"$TMP/helper-calls")" == "/x/helper off card1-DP-1" ]] ||
    fail "the screens turned off were: $(tr '\n' ' ' <"$TMP/helper-calls")"
grep -q 'kept HDMI-A-2 connected: it mirrors HDMI-A-1' "$TMP/log" || fail "the mirror was not kept as one"
unset -f pw-dump sudo hyprctl

printf 'PASS gaming-mode\n'
