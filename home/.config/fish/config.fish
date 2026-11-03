# The login environment lives in ~/.profile; a shell that did not inherit it
# (a TTY or SSH login) sources it.
set -q DOTFILES_PROFILE; or source ~/.profile

if status is-interactive
    # Keep CachyOS fish integration, then silence the greeting.
    if test -f /usr/share/cachyos-fish-config/cachyos-config.fish
        source /usr/share/cachyos-fish-config/cachyos-config.fish
    end
    function fish_greeting
    end
    # Per-project environments (.envrc, e.g. `use flake` or devenv).
    if command -q direnv
        direnv hook fish | source
    end
end
