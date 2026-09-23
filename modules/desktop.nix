# Hyprland/kitty/noctalia/swash/herdr/uwsm: config text only.
# Binaries + GPU + drivers stay with pacman/CachyOS — do NOT enable
# wayland.windowManager.hyprland here (nothing to generate; raw files win).
#
# hypr/ and kitty/ MUST stay recursive directory sources, not per-file
# entries: HM stages every per-file source as its own isolated store object,
# scattering Lua siblings across /nix/store. Hyprland canonicalizes the entry
# file (realpath) and resolves require("config.*") next to the canonical
# location, so scattered per-file links fail at (re)load. A recursive dir
# keeps one staged tree: entry and siblings share a canonical root. Same
# hazard applies to kitty's `include themes/...`.
{ lib, ... }:
let
  hidden = "[Desktop Entry]\nType=Application\nHidden=true\n";
in
{
  xdg.configFile = {
    "hypr" = {
      source = ../files/hypr;
      recursive = true;
    };
    "kitty" = {
      source = ../files/kitty;
      recursive = true;
    };
    "noctalia/config.toml".source = ../files/noctalia.toml;
    "herdr/config.toml".source = ../files/herdr.toml;
    "uwsm/env".source = ../files/uwsm-env;
    # gnome-keyring runs from its systemd socket (unlocked by PAM at login);
    # the XDG autostart copies would start a second daemon.
    "autostart/gnome-keyring-secrets.desktop".text = hidden;
    "autostart/gnome-keyring-pkcs11.desktop".text = hidden;
  };
  # i3bar-style workspace buttons and separators (a local Noctalia plugin).
  # Copied in place rather than linked: Noctalia hot-reloads a plugin when its
  # files change, and writing into the existing files keeps its watches valid.
  home.activation.i3barPlugin = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
    dst="$HOME/.local/share/noctalia/plugins/i3bar"
    src=${../files/noctalia-plugins/i3bar}
    [ -L "$dst" ] && run rm "$dst"
    run mkdir -p "$dst"
    for f in "$src"/*; do
      t="$dst/$(basename "$f")"
      cmp -s "$f" "$t" || run cp --no-preserve=mode "$f" "$t"
    done
    for t in "$dst"/*; do
      [ -e "$src/$(basename "$t")" ] || run rm -f "$t"
    done
  '';
  # Noctalia's file watcher misses Home Manager's symlink swaps; reload it so
  # config and plugin changes apply on switch.
  home.activation.reloadNoctalia = lib.hm.dag.entryAfter [ "linkGeneration" "i3barPlugin" ] ''
    if /usr/bin/pgrep -x noctalia >/dev/null; then
      run /usr/bin/noctalia msg config-reload >/dev/null || true
    fi
  '';
  # Swash rewrites its own settings, so seed them once instead of linking a
  # read-only copy that the app would replace.
  home.activation.seedSwashSettings = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if [ ! -e "$HOME/.config/swash/settings.ini" ]; then
      run install -Dm644 ${../files/swash.ini} "$HOME/.config/swash/settings.ini"
    fi
  '';
  home.sessionVariables.BROWSER = "firefox";
}
