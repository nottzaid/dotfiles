#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-bash-startup.XXXXXX")"
trap 'rm -rf -- "$TMP"' EXIT

# A fresh interactive Bash and fish, with nothing inherited, both get
# ~/.local/bin onto PATH from ~/.profile, once.
mkdir -p "$TMP/home"
ln -s "$ROOT/home/.profile" "$TMP/home/.profile"
fresh=(env -u DOTFILES_PROFILE HOME="$TMP/home" PATH="/usr/bin:/bin")
"${fresh[@]}" bash --noprofile --rcfile "$ROOT/home/.bashrc" -ic \
    'case ":$PATH:" in *":$HOME/.local/bin:"*) ;; *) exit 1 ;; esac' ||
    { printf 'FAIL bash did not load ~/.profile\n' >&2; exit 1; }
if command -v fish >/dev/null 2>&1; then
    # (Run in the scratch home: XDG_CONFIG_HOME would point fish at the real config.)
    path=$("${fresh[@]}" XDG_CONFIG_HOME="$TMP/home/.config" fish --no-config -c \
        "source $ROOT/home/.config/fish/config.fish; string join : \$PATH")
    [[ ":$path:" == *":$TMP/home/.local/bin:"* && ":$path:" == *":/usr/bin:"* ]] ||
        { printf 'FAIL fish PATH from ~/.profile is %s\n' "$path" >&2; exit 1; }
    [[ $(tr ':' '\n' <<<"$path" | grep -cx "$TMP/home/.local/bin") == 1 ]] ||
        { printf 'FAIL fish PATH has ~/.local/bin more than once: %s\n' "$path" >&2; exit 1; }
fi

printf '%s\n' 'PASS fresh Bash and fish load ~/.profile'
