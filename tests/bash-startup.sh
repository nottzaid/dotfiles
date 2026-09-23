#!/usr/bin/env bash
set -euo pipefail

TMP="$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-bash-startup.XXXXXX")"
trap 'rm -rf -- "$TMP"' EXIT

# The managed ~/.bashrc (owned by `home-manager switch`)
# must bring $HOME/.local/bin onto PATH for fresh interactive shells.
# $HOME is pointed at a disposable dir so the assertion covers the
# dynamic session PATH, not leftovers from the current environment.
# The rcfile is the real one; only the shell's HOME is disposable, and the
# caller's "already sourced" guard must not leak in.
rcfile="$HOME/.bashrc"
mkdir -p "$TMP/home"
env -u __HM_SESS_VARS_SOURCED HOME="$TMP/home" PATH="/usr/bin:/bin" \
    bash --noprofile --rcfile "$rcfile" -ic \
    'case ":$PATH:" in *":$HOME/.local/bin:"*) ;; *) exit 1 ;; esac'

printf '%s\n' 'PASS fresh interactive Bash loads the Home Manager session PATH'
