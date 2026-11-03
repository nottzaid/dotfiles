-- Auto-start. UWSM already exports the session environment to systemd/D-Bus;
-- other autostart programs belong in XDG autostart.

hl.on("hyprland.start", function ()
    hl.exec_cmd("noctalia")
end)
