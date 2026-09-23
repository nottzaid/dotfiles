#!/usr/bin/env bash

set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
failures=0

pass() { printf 'PASS %s\n' "$*"; }
fail() { printf 'FAIL %s\n' "$*" >&2; failures=$((failures + 1)); }

HM_GEN="$(readlink -f -- "${HOME}/.local/state/nix/profiles/home-manager" 2>/dev/null || true)"
if [[ "${DOTFILES_SKIP_HM:-0}" == 1 ]]; then
    HM_GEN=""
elif [[ -z "$HM_GEN" || ! -e "$HM_GEN/home-files" ]]; then
    fail "no active Home Manager generation"
    HM_GEN=""
fi

check_managed() {
    local rel="$1" dest resolved="" expected=""
    dest="$HOME/$rel"
    if [[ -n "$HM_GEN" ]]; then
        expected="$(readlink -f -- "$HM_GEN/home-files/$rel" 2>/dev/null || true)"
    fi
    if [[ -n "$expected" && -L "$dest" ]]; then
        resolved="$(readlink -f -- "$dest" 2>/dev/null || true)"
    fi
    if [[ -n "$expected" && "$resolved" == "$expected" ]]; then
        pass "$rel"
    else
        fail "$rel is not deployed from the current Home Manager generation"
    fi
}

git -C "$ROOT" diff --check || fail "repository whitespace"
git -C "$ROOT" submodule status --recursive | while read -r state _; do
    [[ "$state" != -* && "$state" != +* && "$state" != U* ]]
done || fail "submodule revisions"

syntax_failures=0
for script in "$ROOT/install.sh" "$ROOT/verify.sh" "$ROOT"/files/bin/* "$ROOT"/tests/*.sh; do
    [[ -f "$script" ]] || continue
    case "$(head -n1 -- "$script")" in
        *python*) check=(python3 -c 'import ast, sys; ast.parse(open(sys.argv[1]).read())') ;;
        *) check=(bash -n) ;;
    esac
    if ! "${check[@]}" "$script"; then
        fail "Syntax: ${script#"$ROOT"/}"
        syntax_failures=$((syntax_failures + 1))
    fi
done
((syntax_failures == 0)) && pass "Script syntax"

# Every path the old symlink farm owned must now resolve into the
# Home Manager generation; resolving under $ROOT or dangling fails.
# Skipped when DOTFILES_SKIP_HM=1 (disposable-HOME tests without nix).
if [[ "${DOTFILES_SKIP_HM:-0}" != 1 ]]; then
check_managed ".bashrc"
check_managed ".bash_profile"
check_managed ".profile"
check_managed ".config/fish/config.fish"
check_managed ".config/hypr/hyprland.lua"
check_managed ".config/hypr/config/windowrules.lua"
check_managed ".config/noctalia/config.toml"
check_managed ".config/swash/settings.ini"
check_managed ".config/herdr/config.toml"
check_managed ".config/kitty/kitty.conf"
check_managed ".emacs.d/init.el"
check_managed ".config/nvim/nvim-pack-lock.json"
check_managed ".local/bin/swash-screenshot"
check_managed ".local/bin/wait-for-tcp"
check_managed ".local/bin/launcher-curate"
check_managed ".config/launcher-curate/rules"
check_managed "Pictures/background.jpg"
check_managed "Pictures/lockscreen.jpg"
fi

if command -v pnpm >/dev/null 2>&1 && command -v uv >/dev/null 2>&1; then
    pass "pnpm and uv package-manager policy"
else
    fail "pnpm and uv package-manager policy"
fi

for forbidden in npm npx bun yarn corepack pip pip3 pipx poetry pdm hatch rye conda mamba; do
    if command -v "$forbidden" >/dev/null 2>&1; then
        fail "forbidden package manager is available: $forbidden"
    fi
done

if [[ "$(PATH=/usr/local/sbin:/usr/local/bin:/usr/bin:/bin command -v python3)" == /usr/bin/python3 ]]; then
    pass "distribution Python precedence"
else
    fail "distribution Python precedence"
fi

if PATH=/usr/local/sbin:/usr/local/bin:/usr/bin:/bin \
    /usr/bin/python3 /usr/bin/powerprofilesctl --help >/dev/null 2>&1; then
    pass "powerprofilesctl system Python"
else
    fail "powerprofilesctl system Python"
fi

if command -v Hyprland >/dev/null 2>&1; then
    if [[ "${DOTFILES_SKIP_HM:-0}" != 1 ]]; then
        if Hyprland --verify-config --config "$HOME/.config/hypr/hyprland.lua" 2>&1 |
            grep -q 'config ok'; then
            pass "Hyprland live config"
        else
            fail "Hyprland live config"
        fi
    fi
    if Hyprland --verify-config --config "$ROOT/files/hypr/hyprland.lua" 2>&1 |
        grep -q 'config ok'; then
        pass "Hyprland tracked config"
    else
        fail "Hyprland tracked config"
    fi
fi

if command -v hyprctl >/dev/null 2>&1 && [[ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]]; then
    errors="$(hyprctl configerrors)"
    if [[ -z "$errors" ]]; then
        pass "Hyprland config"
    else
        fail "Hyprland config: $errors"
    fi
fi

if command -v nvim >/dev/null 2>&1; then
    if timeout 300s nvim --headless +qa >/dev/null 2>&1; then
        pass "Neovim config"
    else
        fail "Neovim config"
    fi
fi

if ((failures)); then
    printf '%d verification failure(s)\n' "$failures" >&2
    exit 1
fi
printf 'All Home Manager workstation checks passed.\n'
