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
#
# Machine differences come from modules/host.nix: the Hyprland tree gets the
# host's config/host.lua merged in (one tree, for the reason above), uwsm/env
# gets the host's additions, and Noctalia's config gets the host's overrides.
{ config, lib, pkgs, ... }:
let
  hidden = "[Desktop Entry]\nType=Application\nHidden=true\n";
  cfg = config.dotfiles;
  hostDir = ../files/hosts + "/${cfg.host}";

  hyprTree = pkgs.runCommand "hypr-config-${cfg.host}" { } ''
    cp -r ${../files/hypr} $out
    chmod -R u+w $out
    cp -r ${hostDir + "/hypr"}/. $out/
  '';

  hostEnv = hostDir + "/uwsm-env";
  uwsmEnv =
    builtins.readFile ../files/uwsm-env
    + lib.optionalString (builtins.pathExists hostEnv) ("\n" + builtins.readFile hostEnv);

  noctaliaBase = lib.recursiveUpdate (builtins.fromTOML (builtins.readFile ../files/noctalia.toml)) cfg.noctalia;
  noctaliaConfig = lib.recursiveUpdate noctaliaBase {
    bar.default.end = lib.concatMap (w: if w == "clock" then cfg.noctaliaStatusExtra ++ [ w ] else [ w ]) noctaliaBase.bar.default.end;
  };
in
{
  xdg.configFile = {
    "hypr" = {
      source = hyprTree;
      recursive = true;
    };
    "kitty" = {
      source = ../files/kitty;
      recursive = true;
    };
    "noctalia/config.toml".source = (pkgs.formats.toml { }).generate "noctalia-config.toml" noctaliaConfig;
    "herdr/config.toml".source = ../files/herdr.toml;
    "uwsm/env".text = uwsmEnv;
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
      # Noctalia's IPC socket is named after the Wayland display; outside the
      # session (e.g. over SSH) take the display from the socket itself.
      display="''${WAYLAND_DISPLAY:-}"
      if [ -z "$display" ]; then
        sock=$(ls "/run/user/$(id -u)"/noctalia-wayland-*.sock 2>/dev/null | grep -v dmenu | head -1)
        display=$(basename "$sock" .sock | sed 's/^noctalia-//')
      fi
      WAYLAND_DISPLAY="$display" run /usr/bin/noctalia msg config-reload >/dev/null || true
    fi
  '';
  # Hyprland auto-reloads while links are still being swapped and can catch a
  # half-updated tree (a `require` of a file not linked yet). Reload once more
  # after linking; config-only leaves the monitors alone.
  home.activation.reloadHyprland = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
    if [ -n "$(ls "/run/user/$(id -u)/hypr" 2>/dev/null)" ]; then
      run /usr/bin/hyprctl --instance 0 reload config-only >/dev/null || true
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
