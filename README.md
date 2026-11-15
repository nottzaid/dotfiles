# Dotfiles

My CachyOS / Hyprland desktop and laptop configuration.

From this checkout, with GNU Stow installed:

```sh
stow --no-folding -t ~ home
stow --no-folding -d hosts -t ~ desktop # or laptop
systemctl --user enable earshotd flameshot launcher-curate.path launcher-curate.service emacs
```

Existing files can conflict with Stow; review them before replacing them.
These links make checkout edits live.

- [packages/](packages/): package lists and the Flameshot PKGBUILD.
- [hosts/](hosts/): monitor and bar settings. After changing desktop display mode, run `hypr-display-reload`.
- [seed/](seed/): copy once; apps rewrite these files.
- [system/](system/): install manually as root; `etc/` maps to `/etc/`, `libexec/` to `/usr/local/libexec/`.
- [tests/](tests/): run the shell scripts individually.

Bindings live in [binds.lua](home/.config/hypr/config/binds.lua).
