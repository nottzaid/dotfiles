# Current CachyOS workstation

This branch tracks the configuration actually used on the machine: CachyOS
Hyprland with Noctalia, Kitty launching Herdr, Flameshot screenshots, Emacs,
Neovim, and shell startup. Credentials, logs, sessions, caches, backups, and
other mutable state stay in the home directory.

The previous workstation stack is preserved unchanged on
`archived/CachyOS-legacy`. GitHub only supports archival at repository level,
so the branch name and this notice are the branch-level archive marker.

## Layout

| Path | What |
| --- | --- |
| `home/` | Every machine's dotfiles, at the same path under `~` |
| `hosts/desktop/`, `hosts/laptop/` | Each machine's own files, also at their path under `~`: Hyprland's `host.lua` (monitors), Noctalia's `host.toml` (its bars), the desktop's NVIDIA variables and display scripts |
| `seed/` | Settings the apps rewrite themselves (Flameshot): copied once, never linked |
| `packages/` | pacman and AUR package lists, and a local PKGBUILD |
| `system/` | Root-level files, at the same path under `/` (`system/etc/...` is `/etc/...`, `system/libexec/...` is `/usr/local/libexec/...`), placed by hand, plus the settings under Root-level settings |

Each file is linked into place, one link per file, so the repository is the
live config: an edit here is an edit there. On a machine (the desktop here):

```sh
stow --no-folding -t ~ home
stow --no-folding -d hosts -t ~ desktop
systemctl --user enable earshotd flameshot launcher-curate.path launcher-curate.service emacs
```

`--no-folding` keeps directories such as `~/.config/systemd/user` real, so
what apps and `systemctl` write there stays out of the repository. A new
file needs the `stow` line again. Hyprland loads `host.lua` from
`~/.config/hypr` by its path (`hyprland.lua`); Noctalia merges every
`*.toml` in its config folder; uwsm sources `~/.config/uwsm/env.d/*`.

pacman owns every program. Nix (pacman's) is for projects' own
environments, plus the CLI tools pacman lacks, installed with
`nix profile add nixpkgs#exercism nixpkgs#subfinder` (and `signal-cli` on the
laptop).

### Root-level settings

Made by editing files in place:

- `/etc/resolv.conf` links to systemd-resolved's stub.
- `/etc/conf.d/wireless-regdom`: `WIRELESS_REGDOM="JO"`.
- `/etc/pam.d/greetd`: `pam_gnome_keyring.so` after the `system-local-login`
  auth and session lines (unlocks the keyring at login).
- `/etc/pacman.conf`: `CheckSpace`.
- `/etc/nix/nix.conf`: `experimental-features = nix-command flakes`,
  `max-jobs = auto`, `auto-optimise-store = true`.
- GRUB machines: no `nvme_load=YES`, `GRUB_DISABLE_OS_PROBER='true'`.
- Services: `NetworkManager-wait-online` off; `paccache.timer` and
  `nix-daemon.socket` on; Docker by `docker.socket` only; Bluetooth off
  without an adapter.
- Desktops only (no battery): Wi-Fi power saving off and the no-roaming-scan
  dispatcher (`system/etc/NetworkManager`).

## Features

- **Displays:** Super+Shift+M switches the desktop between mirror and
  extended (`display-mode`) until logout; every login starts in the `MODE` set
  in `hosts/desktop/.config/hypr/host.lua`. After changing that default,
  run `hypr-display-reload`, not a plain `hyprctl reload`. Super+Alt+M
  disconnects the TV (freeing what Hyprland holds for it) or connects it again.
- **Scratchpad world:** Super+S switches a screen to its own hidden
  workspaces 1-10 (ids 101-110 on one screen, 201-210 on the next), sliding
  vertically; the same workspace keys and the bar work inside it, and
  Super+Shift+S sends a window to the other world. `scratch-world` routes
  every workspace key.
- **Gaming workspace:** the window rules send games (Steam/Proton, gamescope,
  anything tagged as a game) to the named `gaming` workspace. It has no
  number, so the workspace keys and the bar skip it: Super+G goes there and,
  pressed again, back to where you were; Super+Shift+G sends the focused
  window there, or back.
- **Emacs:** runs as a daemon from login (pacman's unit, enabled), so Super+E opens a frame at once instead of cold-starting
  Emacs. `systemctl --user restart emacs` reloads `init.el`.
- **Launcher:** `launcher-curate` hides entries that cannot open a window
  (terminal programs, missing programs/libraries/files) and applies the rules
  in `~/.config/launcher-curate/rules`; it re-runs whenever applications change.
  `launcher-curate --list` shows every decision.
- **Home layout:** tools keep state under the XDG base directories
  (`~/.profile`); unused user directories are disabled (`user-dirs.dirs`).

## Tests

```sh
./tests/bash-startup.sh
./tests/hypr-reload.sh
./tests/display-mode.sh
./tests/launcher-curate.sh
./tests/scratch-world.sh
./tests/emacs-state.sh
```

They use disposable homes and check the real application configs (both
monitor modes, launcher curation, Emacs recovery).
