#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-gaming-mode.XXXXXX")"
trap 'rm -rf -- "$TMP"' EXIT
script="$ROOT/files/bin/gaming-mode"
helper="$ROOT/system/libexec/gaming-mode-display"
writeback="$ROOT/system/libexec/zram-writeback"

fail() { printf 'FAIL %s\n' "$*" >&2; exit 1; }

# The wiring: the deployed script, the hook that runs it, the root helper and
# the sudoers rule that lets it run without a password.
grep -Fq 'files/bin/gaming-mode' "$ROOT/modules/tools.nix" || fail "modules/tools.nix does not deploy gaming-mode"
grep -Fq 'require("config.gaming")' "$ROOT/files/hypr/hyprland.lua" || fail "hyprland.lua does not load config.gaming"
grep -Fq 'hl.exec_cmd("~/.local/bin/gaming-mode sync")' "$ROOT/files/hypr/config/gaming.lua" ||
    fail "gaming.lua does not run gaming-mode sync"
grep -Fq 'gaming-mode-display' "$ROOT/system/apply.sh" || fail "system/apply.sh does not install the display helper"
[[ "$(grep -v '^#' "$ROOT/system/etc/sudoers.d/gaming-mode")" == "$(printf '%s\n' \
    '%wheel ALL=(root) NOPASSWD: /usr/local/libexec/gaming-mode-display' \
    '%wheel ALL=(root) NOPASSWD: /usr/local/libexec/zram-writeback')" ]] ||
    fail "the sudoers rules name something other than the helpers"
for f in zram-writeback systemd-zram-setup@.service.d/writeback.conf; do
    grep -Fq "$f" "$ROOT/system/apply.sh" || fail "system/apply.sh does not install $f"
done
grep -Fxq 'ExecStartPre=-/usr/local/libexec/zram-writeback attach %i' \
    "$ROOT/system/etc/systemd/system/systemd-zram-setup@.service.d/writeback.conf" ||
    fail "zram swap is not given its disk before it is set up (or failing to stops it)"
for f in gaming-mode-art gaming-mode-review; do
    grep -Fq "files/bin/$f" "$ROOT/modules/tools.nix" || fail "modules/tools.nix does not deploy $f"
done
grep -Fq 'files/quickshell/gaming-mode/shell.qml' "$ROOT/modules/tools.nix" || fail "modules/tools.nix does not deploy the panel"
grep -Fq 'hl.exec_cmd("~/.local/bin/gaming-mode backdrop")' "$ROOT/files/hypr/config/gaming.lua" ||
    fail "gaming.lua does not follow fullscreen changes for the backdrop"
grep -Fq 'function GamingWorkspaceShow()' "$ROOT/files/hypr/config/binds.lua" || fail "binds.lua has no GamingWorkspaceShow for the panel"
grep -Fq 'namespace = "^(wallpaper|gaming-mode-.+)$" }, no_anim = true' "$ROOT/files/hypr/config/windowrules.lua" ||
    fail "the backdrop and the panel may fade out (a screen-sized snapshot)"
for pkg in swaybg quickshell python-numpy python-pillow; do
    grep -Fxq "$pkg" "$ROOT/packages/desktop.txt" || fail "packages/desktop.txt lacks $pkg"
done

# The helpers run as root: they must refuse anything but their words, a
# device name and (writeback) a number of seconds, before touching anything.
for args in "" "on card1-HDMI-A-1" "off HDMI-A-1" "off card1-../../power/state" "detect card1-a/b"; do
    # shellcheck disable=SC2086 # the words are the arguments
    if sh "$helper" $args >/dev/null 2>&1; then fail "the display helper accepted '$args'"; fi
done
for args in "" "writeback" "writeback zram0" "writeback zram0 0" "writeback zram0 86401" "writeback zram0 1x" \
    "writeback zram0 -5" "writeback ../zram0 5" "writeback sda 5" "writeback zram0 5 6" "attach zram0 x" \
    "detach zram0 x" "bogus zram0" "attach zram" "attach zram123"; do
    # shellcheck disable=SC2086 # the words are the arguments
    if sh "$writeback" $args >/dev/null 2>&1; then fail "the writeback helper accepted '$args'"; fi
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
RECLAIM_LATER=0 reclaim_cold "$cg"
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

# --- the journal, the review, the panel's buttons -----------------------------

# Every journal line is JSON, whatever the text holds, and says it back.
SESSIONS="$TMP/sessions" SESSION="$TMP/session"
unset NOTE_DIR
mkdir -p "$SESSIONS/1"
echo 1 >"$SESSION"
odd=$'quote " back \\ tab\t newline\n bell\a ünï ]==] $(x) `y`'
note stop name="$odd" n:=42 ok:=true empty:=
jq -e --arg odd "${odd//$'\a'/}" '.kind == "stop" and .name == $odd and .n == 42 and .ok == true and .empty == null and (.t | type) == "number"' \
    "$SESSIONS/1/events.jsonl" >/dev/null || fail "a journal line does not read back: $(cat "$SESSIONS/1/events.jsonl")"
echo 9 >"$SESSION"
note stop name=x # (a stay whose directory is gone: nothing, and no failure)
[[ ! -e $SESSIONS/9 ]] || fail "note made a journal for a stay that has none"
for _ in $(seq 1 12); do new_session; done
[[ $(find "$SESSIONS" -mindepth 1 -maxdepth 1 -type d | wc -l) == 10 ]] || fail "new_session does not keep the last ten stays"
[[ -d $SESSIONS/$(<"$SESSION") ]] || fail "the current stay has no journal"

# The review reads a stay's journal and gaming-mode's records: a shell that
# never came back after three tries is an error with try-again and forget; a
# readout lists what slept, alike apps counted together. A half-written last
# line is skipped.
reviewer="$ROOT/files/bin/gaming-mode-review"
mkdir -p "$TMP/nohypr"
printf '#!/bin/sh\nexit 1\n' >"$TMP/nohypr/hyprctl"
chmod +x "$TMP/nohypr/hyprctl"
st="$TMP/review-run/gaming-mode"
mkdir -p "$st/sessions/20261016-1-1" "$st/shell/Ab12"
echo 20261016-1-1 >"$st/session"
echo 3 >"$st/shell/Ab12/tries"
touch "$st/on" "$st/left"
cat >"$st/sessions/20261016-1-1/events.jsonl" <<'EOF'
{"kind":"enter","t":1000,"trigger":"workspace","game":[{"pid":1,"class":"steam_app_1","title":"Some Game","fullscreen":2}],"oom_kills":0}
{"kind":"stop","t":1001,"name":"noctalia","record":"Ab12"}
{"kind":"screen","t":1002,"name":"HDMI-A-2","connector":"card1-HDMI-A-2","action":"off"}
{"kind":"freeze","t":1003,"cgroup":"app-graphical.slice/app-Hyprland-kitty-3862fb78.scope","memory":10}
{"kind":"freeze","t":1003,"cgroup":"app-graphical.slice/kitty-8949-0.scope","memory":10}
{"kind":"freeze","t":1003,"cgroup":"app-Some\\x20Game@0a1b.service","memory":10}
{"kind":"close","t":1004,"terminal":"kitty","client":"herdr","workspace":"3","record":"Cd34"}
{"kind":"vram","t":1006,"desktop_before":731,"desktop_after":225}
{"kind":"leave","t":4000,"trigger":"left","game":[]}
{"kind":"gave_up","t":4070,"retries":6}
{"kind":"half a line
EOF
got=$(XDG_RUNTIME_DIR="$TMP/review-run" PATH="$TMP/nohypr:$PATH" python3 "$reviewer" --readout 20261016-1-1)
want='{"since": "'"$(date -d @1000 +%H:%M)"'", "blocks": [{"kind": "shell", "text": "noctalia"}, {"kind": "screen", "text": "HDMI-A-2"}, {"kind": "app", "text": "kitty ×2", "count": 2}, {"kind": "app", "text": "Some Game", "count": 1}, {"kind": "terminal", "text": "herdr"}, {"kind": "vram", "text": "+506 MiB vram"}]}'
[[ "$(jq -cS . <<<"$got")" == "$(jq -cS . <<<"$want")" ]] || fail "the readout is: $got"
got=$(XDG_RUNTIME_DIR="$TMP/review-run" PATH="$TMP/nohypr:$PATH" python3 "$reviewer")
jq -e '.severity == "error" and .title == "not everything came back"
    and (.items[] | select(.kind == "shell") | .severity == "error" and (.actions | map(.id + ":" + .arg) == ["forget:shell/Ab12"]))
    and any(.findings[]; .severity == "error" and .actions[0].id == "retry")' <<<"$got" >/dev/null ||
    fail "the review of a stay that gave up is: $got"

# A button pressed for an earlier stay does nothing.
STATE_DIR="$TMP/act" SESSION="$TMP/act/session" LOG="$TMP/act/log"
mkdir -p "$STATE_DIR"
echo new >"$SESSION"
if act old kill; then fail "an action for another stay ran"; fi
grep -q 'act kill: for stay old, now new: ignored' "$LOG" || fail "a stale action was not logged as ignored"

# The panel is due after a leave, but never over a game on screen: it waits
# (after pause, or off while the game shows) until the game is off screen.
STATE_DIR="$TMP/panel" REVIEW="$TMP/panel/review" PANEL="$TMP/panel/open"
mkdir -p "$STATE_DIR"
touch "$REVIEW"
: >"$TMP/panel-calls"
systemctl() { echo "systemctl $*" >>"$TMP/panel-calls"; [[ $* != *is-active* ]]; }
systemd-run() { echo "systemd-run $*" >>"$TMP/panel-calls"; }
hyprctl() { echo '[{"name": "HDMI-A-1", "focused": true}]'; }
fake_shown=0
gaming_shown() { return "$fake_shown"; }
panel_follow
[[ -e $REVIEW && ! -s $TMP/panel-calls ]] || fail "the panel opened over a game on screen"
fake_shown=1
panel_follow
[[ ! -e $REVIEW && -e $PANEL ]] && grep -q '^systemd-run .*--unit=gaming-mode-panel.service' "$TMP/panel-calls" ||
    fail "the due panel did not open once the game was off screen: $(cat "$TMP/panel-calls")"
fake_shown=0
panel_follow
[[ ! -e $PANEL ]] && grep -q '^systemctl --user stop -- gaming-mode-panel.service' "$TMP/panel-calls" ||
    fail "the panel stayed over a game back on screen"
unset -f systemctl systemd-run hyprctl gaming_shown

# Ending the game ends what is behind its windows and below them; never a
# process with a window elsewhere, nor Steam's own dialog, nor this script.
bash -c 'sleep 30 & sleep 30 & wait' &
game=$!
sleep 30 &
other=$!
for _ in $(seq 1 50); do (($(pgrep -c -P "$game") == 2)) && break; sleep 0.1; done
hyprctl() {
    [[ "$*" == "-j clients" ]] || return 1
    printf '[{"pid": %s, "class": "steam_app_1", "workspace": {"name": "gaming"}, "address": "0x1"},
              {"pid": %s, "class": "steam", "workspace": {"name": "gaming"}, "address": "0x2"},
              {"pid": %s, "class": "kitty", "workspace": {"name": "1"}, "address": "0x3"},
              {"pid": %s, "class": "x", "workspace": {"name": "gaming"}, "address": "0x4"}]' "$game" "$other" "$$" "$$"
}
want=$( (echo "$game"; pgrep -P "$game") | sort)
[[ "$(game_processes | sort)" == "$want" ]] ||
    fail "the game's processes are: $(game_processes | tr '\n' ' '), not $(tr '\n' ' ' <<<"$want")"
[[ "$(game_window_list address)" == $'0x1\n0x4' ]] || fail "Steam's dialog was taken for the game's window"
pkill -P "$game"
kill "$game" "$other" 2>/dev/null
wait "$game" "$other" 2>/dev/null || true

# An extended TV mirrors the monitor for the stay and is extended again
# after; one switched meanwhile is left as it was; a disconnected or
# unplugged one is set to come back mirroring, and back as it was after.
SESSIONS="$TMP/sessions" SESSION="$TMP/session" STATE_DIR="$TMP/tv" LOG="$TMP/tv/log"
MIRRORED="$TMP/tv/mirrored" BIN_DIR="$TMP/tv/bin"
mkdir -p "$BIN_DIR" "$SESSIONS/tv"
echo tv >"$SESSION"
cat >"$BIN_DIR/display-mode" <<'EOF'
#!/usr/bin/env bash
tv=$TV_DIR
echo "$*" >>"$tv/calls"
now=$(<"$tv/mode")
case $1 in
status) echo "$now" ;;
mirror | extended) [[ ! -e $tv/fails ]] || exit 1; echo "$1" >"$tv/mode" ;;
record) [[ $now == off || $now == none ]] || exit 3; cat "$tv/recorded"; echo "$2" >"$tv/recorded" ;;
*) exit 2 ;;
esac
EOF
chmod +x "$BIN_DIR/display-mode"
export TV_DIR="$TMP/tv"
# tv MODE [RECORDED]: the TV as display-mode reports it, its calls forgotten.
tv() { echo "$1" >"$TV_DIR/mode"; echo "${2:-extended}" >"$TV_DIR/recorded"; : >"$TV_DIR/calls"; : >"$SESSIONS/tv/events.jsonl"; }
calls() { tr '\n' ',' <"$TV_DIR/calls"; }
tv extended
mirror_screens
[[ "$(calls)" == "status,mirror," && -e $MIRRORED && $(<"$TV_DIR/mode") == mirror ]] || fail "an extended TV was not mirrored: $(calls)"
unmirror_screens
[[ "$(calls)" == "status,mirror,status,extended," && ! -e $MIRRORED ]] || fail "the TV was not extended again: $(calls)"
jq -se 'map(.action) == ["mirror", "extend"] and .[1].found == "mirror"' "$SESSIONS/tv/events.jsonl" >/dev/null ||
    fail "the journal of a mirrored stay is: $(cat "$SESSIONS/tv/events.jsonl")"
tv extended
mirror_screens
echo extended >"$TV_DIR/mode" # (switched back by hand meanwhile)
unmirror_screens
[[ "$(calls)" == "status,mirror,status," && ! -e $MIRRORED ]] || fail "a TV extended meanwhile was switched: $(calls)"
tv extended
mirror_screens
echo off >"$TV_DIR/mode" # (disconnected meanwhile)
unmirror_screens
[[ "$(calls)" == "status,mirror,status,record extended," && $(<"$TV_DIR/recorded") == extended ]] ||
    fail "a TV disconnected during the stay comes back as: $(<"$TV_DIR/recorded") ($(calls))"
tv off extended
mirror_screens
[[ $(<"$TV_DIR/recorded") == mirror && -e $MIRRORED && $(<"$TV_DIR/mode") == off ]] ||
    fail "a disconnected TV was connected, or not set to come back mirroring: $(calls)"
unmirror_screens
[[ $(<"$TV_DIR/recorded") == extended && ! -e $MIRRORED ]] || fail "a TV disconnected all stay does not come back extended"
tv off mirror
mirror_screens
[[ $(<"$TV_DIR/recorded") == mirror && ! -e $MIRRORED ]] || fail "a TV recorded as mirroring was set to come back extended"
tv mirror
mirror_screens
[[ "$(calls)" == "status," && ! -e $MIRRORED ]] || fail "a mirroring TV was switched: $(calls)"
tv extended
touch "$TV_DIR/fails"
mirror_screens
[[ ! -e $MIRRORED ]] && jq -e '.action == "mirror" and .ok == false' "$SESSIONS/tv/events.jsonl" >/dev/null ||
    fail "a failed mirror was recorded as done"
rm "$TV_DIR/fails"
BIN_DIR="$TMP/nowhere" mirror_screens || fail "a host without display-mode failed"

# The game closing keeps gaming mode on while its workspace is on screen,
# noted once; the workspace leaving the screen ends the stay.
# shellcheck disable=SC2034 # read by follow
ON="$TMP/tv/on" LEFT="$TMP/tv/left" PINNED="$TMP/tv/pinned"
touch "$ON"
: >"$TMP/follow-calls"
gaming_shown() { return "$fake_shown"; }
leave_or_retry() { echo leave >>"$TMP/follow-calls"; }
backdrop_follow() { echo backdrop >>"$TMP/follow-calls"; }
tv extended
fake_shown=3
follow
follow
[[ "$(tr '\n' ' ' <"$TMP/follow-calls")" == "backdrop backdrop " ]] || fail "the game closing ended the stay: $(cat "$TMP/follow-calls")"
[[ "$(jq -s 'map(select(.kind == "game_closed")) | length' "$SESSIONS/tv/events.jsonl")" == 1 ]] ||
    fail "the game closing was not noted once: $(cat "$SESSIONS/tv/events.jsonl")"
fake_shown=1
follow
[[ "$(tail -1 "$TMP/follow-calls")" == leave ]] || fail "the workspace leaving the screen did not end the stay"
rm "$ON"
: >"$TMP/follow-calls"
fake_shown=3
follow
[[ "$(cat "$TMP/follow-calls")" == backdrop ]] || fail "the empty gaming workspace (the lobby) did not get its backdrop"
unset -f gaming_shown leave_or_retry backdrop_follow tv calls

# Steam's UI: ended under the game's Steam with its sandbox stopped first,
# and left running when any of it is the game's, when nothing stands between
# it and Steam, and when the Steam it is under is not the game's (frozen
# whole instead). The user's systemd 5 > bash 9 > Steam 10 > srt-bwrap 20 >
# pv-adverb 30 > browser 40 > renderer 41, a crash handler 42 under
# pv-adverb; all but systemd in Steam's unit S.
(
    STEAMUI="$TMP/steam-ui" ON="$TMP/steam-on" LEFT="$TMP/steam-left" SESSION="$TMP/steam-session"
    declare -A fake_parent fake_cg
    steam_tree() {
        fake_ui=$'40\n41\n42'
        fake_parent=([9]=5 [10]=9 [20]=10 [30]=20 [40]=30 [41]=40 [42]=30 [5]=1)
        fake_cg=([5]=/user)
        PROTECTED=$'5\n10'
        PROTECTED_CG=$'/user\nS'
        fake_state=T
        rm -rf "$STEAMUI"
        : >"$TMP/steam-calls"
    }
    steam_ui_pids() { [[ -n $fake_ui ]] && echo "$fake_ui"; }
    parent_of() { echo "${fake_parent[$1]:-}"; }
    cgroup_of() { echo "${fake_cg[$1]:-S}"; }
    starttime_of() { echo "s$1"; }
    state_of() { echo "$fake_state"; }
    same_process() { [[ " ${fake_gone:-} " != *" $1 "* ]]; }
    kill() { echo "kill $*" >>"$TMP/steam-calls"; [[ $1 == -KILL ]] && fake_ui=""; return 0; }
    sleep() { :; }
    # shellcheck disable=SC2034 # read by stop_steam_ui
    CLIENTS='[{"pid": 40, "title": "Steam", "workspace": {"name": "2"}}, {"pid": 40, "title": "Settings", "workspace": {"name": "2"}}]'
    steam_tree
    stop_steam_ui
    [[ "$(cat "$STEAMUI/parked")" == $'30 s30\n20 s20' ]] || fail "the sandbox was not recorded: $(cat "$STEAMUI/parked")"
    [[ "$(cat "$TMP/steam-calls")" == $'kill -STOP 30 20\nkill -KILL 40 41 42' ]] ||
        fail "Steam's UI was not ended behind a stopped sandbox: $(cat "$TMP/steam-calls")"
    [[ "$(cat "$STEAMUI/windows")" == $'Steam\t2' ]] || fail "Steam's windows were not recorded: $(cat "$STEAMUI/windows")"
    # Ended already: nothing more, until Steam's UI runs again with the record left.
    : >"$TMP/steam-calls"
    stop_steam_ui
    [[ ! -s $TMP/steam-calls ]] || fail "an ended UI was ended again: $(cat "$TMP/steam-calls")"
    fake_ui=$'40\n41\n42'
    echo "20 s20" >"$STEAMUI/parked"
    stop_steam_ui
    [[ "$(cat "$TMP/steam-calls")" == $'kill -CONT 20\nkill -STOP 30 20\nkill -KILL 40 41 42' ]] ||
        fail "a record left by an unfinished leave was not let go on first: $(cat "$TMP/steam-calls")"
    # Letting go on: a process that ended meanwhile is no failure; the record goes.
    : >"$TMP/steam-calls"
    command() { [[ $* != "-v steam" ]] && builtin command "$@"; }
    fake_gone=30 start_steam_ui || fail "Steam's sandbox was not let go on"
    [[ "$(cat "$TMP/steam-calls")" == "kill -CONT 20" && ! -e $STEAMUI ]] ||
        fail "Steam's sandbox did not go on: $(cat "$TMP/steam-calls")"
    for case in "the browser is the game's" "no sandbox" "Steam is not the game's" "the game is not below Steam" "the sandbox does not stop"; do
        steam_tree
        # shellcheck disable=SC2034 # read by stop_steam_ui
        case $case in
            "the browser is the game's") PROTECTED+=$'\n40' ;;
            "no sandbox") fake_parent[40]=10 fake_parent[42]=10 ;;
            "Steam is not the game's") PROTECTED=5 PROTECTED_CG=/user ;;
            "the game is not below Steam") PROTECTED=5 ;;
            "the sandbox does not stop") fake_state=S ;;
        esac
        stop_steam_ui
        [[ ! -e $STEAMUI ]] && ! grep -q -- -KILL "$TMP/steam-calls" || fail "Steam's UI was ended when $case: $(cat "$TMP/steam-calls")"
    done
    [[ "$(cat "$TMP/steam-calls")" == $'kill -STOP 30 20\nkill -CONT 30 20' ]] || fail "a sandbox that did not stop was not let go on"
    # Its windows open again only while off, for the stay that ended them.
    echo 1 >"$SESSION"
    steam_window_due 1 || fail "a window was not due after the stay"
    touch "$ON"
    if steam_window_due 1; then fail "a window was due while a stay is on"; fi
    touch "$LEFT"
    steam_window_due 1 || fail "a window was not due while leaving"
    rm -f "$ON" "$LEFT"
    echo 2 >"$SESSION"
    if steam_window_due 1; then fail "a window was due for an earlier stay"; fi
) || exit 1

# A visit to the desktop (leaving while the game's windows are up) keeps the
# screens' layout and Steam's UI as the stay has them, and the review panel
# for later; they go back once the game's windows are gone, or (Steam's UI)
# once the visit lasts.
(
    # shellcheck disable=SC2034 # read by leave
    ON="$TMP/v/on" LEFT="$TMP/v/left" VISIT="$TMP/v/visit" REVIEW="$TMP/v/review" MIRRORED="$TMP/v/mirrored"
    # shellcheck disable=SC2034 # read by leave
    STEAMUI="$TMP/v/steam-ui" PINNED="$TMP/v/pinned" CLAIMED="$TMP/v/claimed" ANR="$TMP/v/anr" SESSION="$TMP/v/none"
    mkdir -p "$TMP/v"
    for f in thaw_apps start_steam_ui reconnect_displays start_shell unmirror_screens backdrop_leave \
        reopen_terminals restore_layer_fades prerender_later sync_later; do
        eval "$f() { echo $f >>\"\$TMP/v/calls\"; }"
    done
    game_window_list() { [[ -n ${fake_game:-} ]] && echo 0x1; return 0; }
    game_windows() { echo '[]'; }
    visit() { # visit TRIGGER GAME [LEFT-BEFORE]
        rm -rf "$TMP/v/"*
        touch "$ON" "$REVIEW"
        [[ -n ${3:-} ]] && echo "$3" >"$LEFT"
        mkdir -p "$STEAMUI"
        LEAVE_TRIGGER=$1 fake_game=$2 leave
        tr '\n' ' ' <"$TMP/v/calls"
    }
    [[ "$(visit left 1)" == "thaw_apps reconnect_displays start_shell backdrop_leave reopen_terminals restore_layer_fades sync_later prerender_later " ]] ||
        fail "a visit restored the layout or Steam's UI: $(visit left 1)"
    [[ -e $VISIT && ! -e $REVIEW && ! -e $ON ]] || fail "a visit was not recorded, or its review is due"
    [[ "$(visit retry 1 left)" == "$(visit left 1)" ]] || fail "a retried visit was not a visit"
    for args in "left|" "pause|1" "retry|1|pause" "off|1" "pause|1|left" "off|1|left" "retry|1|"; do
        IFS='|' read -r trigger game before <<<"$args"
        out=$(visit "$trigger" "$game" "$before")
        [[ $out == *start_steam_ui*unmirror_screens* && ! -e $VISIT ]] || fail "leaving ($args) kept the stay's layout: $out"
    done
    # Ending it: Steam's UI after STEAM_LATER (asked again until it is back),
    # all of it once the game is gone, the review then, once.
    start_steam_ui() { echo start_steam_ui >>"$TMP/v/calls"; [[ -z ${fake_fail:-} ]] && rm -rf "$STEAMUI"; }
    unmirror_screens() { echo unmirror_screens >>"$TMP/v/calls"; [[ -z ${fake_fail:-} ]] && rm -f "$MIRRORED"; }
    calls() { tr '\n' ' ' <"$TMP/v/calls" 2>/dev/null; : >"$TMP/v/calls"; }
    rm -rf "$TMP/v/"*
    touch "$MIRRORED"
    mkdir -p "$STEAMUI"
    uptime_s >"$VISIT"
    fake_game=1 end_visit
    [[ "$(calls)" == "sync_later " && -e $VISIT ]] || fail "a visit ended early, or Steam's UI was not asked for later"
    echo $(($(uptime_s) - STEAM_LATER)) >"$VISIT"
    fake_fail=1 fake_game=1 end_visit
    [[ "$(calls)" == "start_steam_ui sync_later " ]] || fail "Steam's UI that did not come back was not asked for again"
    fake_game=1 end_visit
    [[ "$(calls)" == "start_steam_ui " && -e $VISIT && ! -e $REVIEW ]] || fail "Steam's UI did not come back as the visit lasted"
    fake_game=1 end_visit
    [[ -z "$(calls)" ]] || fail "a visit with Steam's UI back asked for more"
    fake_fail=1 fake_game="" end_visit
    [[ "$(calls)" == "start_steam_ui unmirror_screens " && ! -e $VISIT && -e $REVIEW && -e $MIRRORED ]] ||
        fail "the game gone did not end the stay"
    rm -f "$REVIEW"
    fake_game="" end_visit
    [[ "$(calls)" == "start_steam_ui unmirror_screens " && ! -e $REVIEW && ! -e $MIRRORED ]] ||
        fail "what failed at the end of a stay was not tried again, or the review came twice"
    fake_game="" end_visit
    [[ -z "$(calls)" && ! -e $REVIEW ]] || fail "a desktop with nothing kept from a stay ended one"
    # A visit that held nothing back still ends with its review.
    uptime_s >"$VISIT"
    fake_game="" end_visit
    [[ -e $REVIEW && ! -e $VISIT ]] || fail "a visit that held nothing back ended without its review"
) || exit 1

# The review: the TV's part in the stay, a button for it as it is now, and
# the game closed.
st="$TMP/tv-review/gaming-mode"
mkdir -p "$st/sessions/20261016-2-1"
echo 20261016-2-1 >"$st/session"
cat >"$st/sessions/20261016-2-1/events.jsonl" <<'EOF'
{"kind":"enter","t":1000,"trigger":"workspace","game":[{"pid":1,"class":"steam_app_1","title":"Some Game","fullscreen":2}],"oom_kills":0}
{"kind":"screen","t":1001,"action":"mirror","ok":true}
{"kind":"game_closed","t":1500}
{"kind":"leave","t":1600,"trigger":"left","game":[]}
{"kind":"screen","t":1601,"action":"extend","ok":true,"found":"off"}
EOF
echo off >"$TV_DIR/mode"
review() { XDG_RUNTIME_DIR="$TMP/tv-review" GAMING_MODE_BIN="$BIN_DIR" PATH="$TMP/nohypr:$PATH" python3 "$reviewer" "$@"; }
got=$(review)
jq -e --arg at "$(date -d @1500 +%H:%M)" '
    (.items[] | select(.kind == "screen") | .name == "TV" and .severity == "ok" and .text == "disconnected · comes back extended")
    and any(.findings[]; .text == "Some Game closed at \($at).")
    and any(.findings[]; .text == "The TV is disconnected." and (.actions | map(.id) == ["screen-on"]))' <<<"$got" >/dev/null ||
    fail "the review of a mirrored stay is: $got"
echo mirror >"$TV_DIR/mode"
touch "$st/mirrored"
got=$(review)
jq -e '(.items[] | select(.kind == "screen") | .severity == "wait")
    and any(.findings[]; (.actions | map(.id) == ["screen-off"]))' <<<"$got" >/dev/null ||
    fail "the review of a TV still to extend is: $got"
jq -e '.blocks | any(.kind == "mirror")' <<<"$(review --readout 20261016-2-1)" >/dev/null ||
    fail "the readout does not show the TV mirroring"
GAMING_MODE_BIN="$TMP/nowhere" XDG_RUNTIME_DIR="$TMP/tv-review" PATH="$TMP/nohypr:$PATH" python3 "$reviewer" |
    jq -e 'all(.findings[]; (.text | startswith("The TV") | not))' >/dev/null || fail "a host without a TV got a TV button"
unset -f review

# The backdrop goes on the gaming workspace's screen, unless what that screen
# shows has a fullscreen window ("any" asks regardless); the gaming workspace
# shown with no window is the lobby.
hyprctl() {
    case "$*" in
        "-j monitors") echo "[{\"name\": \"HDMI-A-1\", \"width\": 1920, \"height\": 1080, \"scale\": 1, \"activeWorkspace\": {\"id\": 2}},
                              {\"name\": \"HDMI-A-2\", \"width\": 3840, \"height\": 2160, \"scale\": 2, \"activeWorkspace\": {\"id\": $SHOWN}}]" ;;
        "-j workspaces") echo "[{\"id\": -99, \"name\": \"gaming\", \"monitor\": \"HDMI-A-2\", \"hasfullscreen\": false, \"windows\": 0},
                               {\"id\": 6, \"name\": \"6\", \"monitor\": \"HDMI-A-2\", \"hasfullscreen\": $FS}]" ;;
        "-j clients") echo "[{\"workspace\": {\"id\": 6}, \"hidden\": false, \"size\": [$WIN]},
                            {\"workspace\": {\"id\": 2}, \"hidden\": false, \"size\": [1920, 1080]}]" ;;
        *) return 1 ;;
    esac
}
FS=false WIN="800, 600" SHOWN=6
[[ "$(backdrop_place)" == "HDMI-A-2 3840 2160 -" ]] || fail "the backdrop is not placed on the gaming workspace's screen"
FS=true
[[ -z "$(backdrop_place)" ]] || fail "the backdrop shows under a fullscreen window"
[[ "$(backdrop_place any)" == "HDMI-A-2 3840 2160 -" ]] || fail "the backdrop's size is unknown under a fullscreen window"
FS=false SHOWN=-99
[[ "$(backdrop_place)" == "HDMI-A-2 3840 2160 empty" ]] || fail "the empty gaming workspace was not told apart"
SHOWN=6
# (A window covering the screen without being fullscreen covers it too; the
# screen is 1920x1080 in the compositor's units at scale 2.)
FS=false WIN="1916, 1040"
[[ -z "$(backdrop_place)" ]] || fail "the backdrop shows under a window that covers the screen"
unset -f hyprctl

# The picture: drawn once per wallpaper and size, found again by a fixed name.
if python3 -c 'import numpy, PIL' 2>/dev/null; then
    art="$ROOT/files/bin/gaming-mode-art"
    pic=$(XDG_CACHE_HOME="$TMP/cache" XDG_STATE_HOME="$TMP/nostate" python3 "$art" plain TEST-1 320 180)
    [[ $pic == "$TMP/cache/gaming-mode/plain-TEST-1-320x180.png" && -s $pic ]] || fail "the plain picture is not at its fixed name: $pic"
    echo '{"since": "16:13", "blocks": [{"kind": "app", "text": "kitty"}]}' |
        XDG_CACHE_HOME="$TMP/cache" XDG_STATE_HOME="$TMP/nostate" python3 "$art" readout TEST-1 320 180 "$TMP/r.png" ||
        fail "the readout picture was not drawn"
    [[ "$(python3 -c 'import sys; from PIL import Image; print(*Image.open(sys.argv[1]).size)' "$TMP/r.png")" == "320 180" ]] ||
        fail "the readout picture is not the screen's size"
    rm "$pic"
    XDG_CACHE_HOME="$TMP/cache" XDG_STATE_HOME="$TMP/nostate" python3 "$art" prepare TEST-1 320 180 ||
        fail "prepare failed"
    for kind in plain lobby; do
        [[ -s $TMP/cache/gaming-mode/$kind-TEST-1-320x180.png ]] || fail "prepare did not draw the $kind picture"
    done
fi

printf 'PASS gaming-mode\n'
