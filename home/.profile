# The login environment, for every shell and the graphical session (uwsm
# reads it). Only `export NAME="value"` lines: fish sources this file too
# (~/.config/fish/config.fish), and quoted "$PATH" joins with colons there
# as in sh. Shells that already have it (DOTFILES_PROFILE) skip it.
export DOTFILES_PROFILE=1
export BROWSER="firefox"

# Tools keep their state under the XDG base directories, not in dot-folders.
export GOPATH="$HOME/.local/share/go"
export GOMODCACHE="$HOME/.cache/go/mod"
export CARGO_HOME="$HOME/.local/share/cargo"
export RUSTUP_HOME="$HOME/.local/share/rustup"
export WINEPREFIX="$HOME/.local/share/wine"
export DOCKER_CONFIG="$HOME/.config/docker"
export NPM_CONFIG_CACHE="$HOME/.cache/npm"
export CUDA_CACHE_PATH="$HOME/.cache/nv"
export PNPM_HOME="$HOME/.local/share/pnpm"

# Global installs of pnpm, opencode, cargo, go and nix profile.
export PATH="$HOME/.local/bin:$HOME/.local/share/pnpm/bin:$HOME/.opencode/bin:$HOME/.local/share/cargo/bin:$HOME/.local/share/go/bin:$HOME/.nix-profile/bin:$PATH"
