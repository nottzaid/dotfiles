"""Kitty watcher: keep zmx sessions alive on detach/window close, reap them on explicit Ctrl+b>x, and persist multi-split layouts."""

from __future__ import annotations

import fcntl
import json
import os
import shlex
import subprocess
import time
from pathlib import Path
from typing import Any

from kitty.boss import Boss
from kitty.constants import unserialize_launch_flag
from kitty.session import default_save_as_session_opts
from kitty.window import Window

ZMX_BIN = "/usr/bin/zmx"
RUNTIME_DIR = Path(os.environ.get("XDG_RUNTIME_DIR") or "/tmp")
MAP_DIR = RUNTIME_DIR / f"kitty-zmx-{os.getpid()}"
LOCK_PATH = RUNTIME_DIR / "kitty-zmx.lock"
AUTOSAVE_PATH = Path.home() / ".local" / "share" / "kitty" / "sessions" / "autosave.kitty-session"

_closed_os_windows: set[int] = set()
_quitting = False
_last_save_ts = 0.0
_lock_fd: Any = None
_is_primary = False


def on_load(boss: Boss, data: dict[str, Any]) -> None:
    global _lock_fd, _is_primary
    if os.environ.get("KITTY_ZMX_PRIMARY") != "1":
        return
    try:
        fd = open(LOCK_PATH, "w", encoding="utf-8")
        fcntl.flock(fd.fileno(), fcntl.LOCK_EX | fcntl.LOCK_NB)
        fd.write(f"{os.getpid()}\n")
        fd.flush()
        _lock_fd = fd
        _is_primary = True
    except OSError:
        _is_primary = False


def _read_session_name(wid: int) -> str:
    path = MAP_DIR / str(wid)
    try:
        return path.read_text(encoding="utf-8").strip()
    except OSError:
        return ""


def _drop_map_entry(wid: int) -> None:
    try:
        (MAP_DIR / str(wid)).unlink(missing_ok=True)
    except OSError:
        pass


def _sync_window_env(window: Window) -> str:
    session_name = _read_session_name(window.id)
    if not session_name:
        return ""
    spec = window.creation_spec
    if spec is not None:
        existing_env = tuple((k, v) for k, v in (spec.env or ()) if k != "KITTY_ZMX_SESSION")
        new_env = existing_env + (("KITTY_ZMX_SESSION", session_name),)
        if spec.env != new_env:
            window.creation_spec = spec._replace(env=new_env)
    return session_name


def _inject_session_env_into_line(line: str, session_by_wid: dict[int, str]) -> str:
    if not line.startswith("launch "):
        return line
    try:
        parts = shlex.split(line)
    except ValueError:
        return line
    wid: int | None = None
    has_zmx_env = False
    for part in parts[1:]:
        if part.startswith(unserialize_launch_flag):
            try:
                payload = json.loads(part[len(unserialize_launch_flag):])
                wid = payload.get("id")
            except Exception:
                pass
        elif part.startswith("--env=KITTY_ZMX_SESSION="):
            has_zmx_env = True
    if wid is not None and not has_zmx_env:
        session_name = session_by_wid.get(wid)
        if session_name:
            insert_at = 2 if len(parts) > 1 and parts[1].startswith(unserialize_launch_flag) else 1
            parts.insert(insert_at, f"--env=KITTY_ZMX_SESSION={session_name}")
            return shlex.join(parts)
    return line


def _save_layout(boss: Boss, force: bool = False) -> None:
    global _last_save_ts
    if not _is_primary:
        return
    now = time.monotonic()
    if not force and (now - _last_save_ts) < 0.25:
        return
    _last_save_ts = now

    session_by_wid: dict[int, str] = {}
    for w in boss.all_windows:
        if name := _sync_window_env(w):
            session_by_wid[w.id] = name

    if not session_by_wid and not any(True for _ in boss.all_windows):
        return

    opts = default_save_as_session_opts()
    opts.save_only = True
    lines = [_inject_session_env_into_line(ln, session_by_wid) for ln in boss.serialize_state_as_session(str(AUTOSAVE_PATH), opts)]
    content = "\n".join(lines).strip()
    if not content:
        return

    AUTOSAVE_PATH.parent.mkdir(parents=True, exist_ok=True)
    tmp_path = AUTOSAVE_PATH.with_suffix(".tmp")
    tmp_path.write_text(content + "\n", encoding="utf-8")
    tmp_path.replace(AUTOSAVE_PATH)


def _clear_autosave() -> None:
    if not _is_primary:
        return
    try:
        AUTOSAVE_PATH.unlink(missing_ok=True)
    except OSError:
        pass


def _cleanup_map_dir() -> None:
    try:
        MAP_DIR.rmdir()
    except OSError:
        pass


def on_focus_change(boss: Boss, window: Window, data: dict[str, Any]) -> None:
    if not _quitting and data.get("focused"):
        _save_layout(boss)


def on_resize(boss: Boss, window: Window, data: dict[str, Any]) -> None:
    old_geo = data.get("old_geometry")
    if old_geo is not None and getattr(old_geo, "xnum", 0) > 0 and getattr(old_geo, "ynum", 0) > 0:
        _save_layout(boss)


def on_title_change(boss: Boss, window: Window, data: dict[str, Any]) -> None:
    if not data.get("from_child"):
        _save_layout(boss)


def on_quit(boss: Boss, window: Window, data: dict[str, Any]) -> None:
    global _quitting
    if data.get("confirmed"):
        _save_layout(boss, force=True)
        _quitting = True


def on_close(boss: Boss, window: Window, data: dict[str, Any]) -> None:
    global _quitting
    reason = data.get("reason")
    cause = data.get("cause")
    session_name = _read_session_name(window.id)

    if reason == "window":
        _drop_map_entry(window.id)
        if cause == "closed" and session_name and os.path.exists(ZMX_BIN):
            subprocess.Popen(
                [ZMX_BIN, "kill", session_name],
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
                start_new_session=True,
            )
        if not any(w.id != window.id for w in boss.all_windows):
            _cleanup_map_dir()
            _clear_autosave()
        return

    # Whole OS window closed (detach) or application quit/signal/logout:
    # save full multi-split layout once on the first closing pane, and keep zmx alive.
    if reason == "os_window":
        if window.os_window_id not in _closed_os_windows:
            _save_layout(boss, force=True)
            _closed_os_windows.add(window.os_window_id)
    elif reason == "quit":
        if not _quitting:
            _save_layout(boss, force=True)
            _quitting = True

    _drop_map_entry(window.id)
    if not any(w.id != window.id for w in boss.all_windows):
        _cleanup_map_dir()
