# Current CachyOS workstation

This branch tracks the configuration actually used on the machine: CachyOS
Hyprland with Noctalia, Kitty launching Herdr, Swash screenshots, Emacs,
Neovim, and shell startup. Credentials, logs, sessions, caches, backups, and
other mutable state stay in the home directory.

The previous workstation stack is preserved unchanged on
`archived/CachyOS-legacy`. GitHub only supports archival at repository level,
so the branch name and this notice are the branch-level archive marker.

## Ownership

| Owner | What |
| --- | --- |
| pacman (+ AUR via paru) | Kernel, drivers, GPU stack, desktop, shells, and every tool it packages (`packages/*.txt`) |
| Home Manager (this flake) | All dotfiles, plus the few CLI tools pacman lacks (`modules/tools.nix`) |
| `system/apply.sh` | Root-level configuration: DNS, PAM keyring unlock, GRUB command line, services |

`home.packages` stays minimal on purpose: binaries, GPU, and drivers belong
to pacman, and `verify.sh` fails if a Nix copy of bash, fish, man, or Python
shadows the system one.

## Restore the workstation

On CachyOS or Arch, with pacman's `nix` installed and its daemon enabled:

```sh
git clone --recurse-submodules --branch current \
  https://github.com/nottzaid/dotfiles.git ~/Projects/dotfiles
cd ~/Projects/dotfiles
./install.sh --full
```

| Option | Adds |
| --- | --- |
| (none) | Home Manager switch only |
| `--packages` | Desktop package manifests (pacman, then AUR through paru) |
| `--streaming` | yt-stream-workspace packages and its config template |
| `--system` | Root-level configuration (`system/apply.sh`, via sudo) |
| `--full` | Everything above |

Repeating it is safe. Set `DOTFILES_SKIP_HM=1` to skip the switch (used by
tests on disposable homes without nix).

## Dotfiles via Home Manager

Edit config text under `files/` or options under `modules/`, then apply:

```sh
home-manager switch --flake ~/Projects/dotfiles
```

`hypr/` and `kitty/` must stay `recursive` directory sources: Home Manager
stages every per-file source as its own isolated store object, and Hyprland
resolves Lua `require()` next to the canonicalized entry file, so per-file
links break it.

- **Displays:** set `MODE` in `files/hypr/config/monitors.lua` (`mirror` or
  `extended`), then `hyprctl reload`.
- **Launcher:** `launcher-curate` hides entries that cannot open a window
  (terminal programs, missing programs/libraries/files) and applies the rules
  in `files/launcher-curate.rules`; it re-runs whenever applications change.
  `launcher-curate --list` shows every decision.
- **Home layout:** tools keep state under the XDG base directories
  (`modules/layout.nix`); unused user directories are disabled.
- **Nix:** the `nixpkgs` registry entry is pinned to this flake, and a weekly
  user timer expires old generations and collects garbage.

## Verify

```sh
./verify.sh
./tests/install-smoke.sh
./tests/bash-startup.sh
./tests/hypr-reload.sh
./tests/launcher-curate.sh
./tests/emacs-state.sh
```

The tests use disposable homes, validate the real application configs (both
monitor modes, launcher curation, Emacs recovery), and `verify.sh` checks that
every Home Manager file is deployed and that pacman owns the core tools. For
a clean distribution boundary, run `./tests/distrobox.sh` after installing
Distrobox.

## Update

```sh
git pull --ff-only
git submodule update --init --recursive
./install.sh --full
./verify.sh
```
