#!/usr/bin/env python3
"""Print Hyprland's IPC events (socket2), one per line, for runStream()."""
import os
import socket
import sys

path = os.path.join(os.environ["XDG_RUNTIME_DIR"], "hypr",
                    os.environ["HYPRLAND_INSTANCE_SIGNATURE"], ".socket2.sock")
with socket.socket(socket.AF_UNIX) as sock:
    sock.connect(path)
    for line in sock.makefile(encoding="utf-8", errors="replace"):
        sys.stdout.write(line)
        sys.stdout.flush()
