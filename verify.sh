#!/usr/bin/env bash

set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
failures=0

pass() { printf 'PASS %s\n' "$*"; }
fail() { printf 'FAIL %s\n' "$*" >&2; failures=$((failures + 1)); }

git -C "$ROOT" diff --check || fail "repository whitespace"
if git -C "$ROOT" submodule status --recursive | grep -qE '^[-+U]'; then
    fail "submodule revisions (uninitialized, modified, or conflicted)"
else
    pass "submodule revisions"
fi

# Syntax of every script, with the interpreter its shebang names.
syntax_failures=0
bash_scripts=()
for script in "$ROOT/install.sh" "$ROOT/verify.sh" "$ROOT/system/apply.sh" \
    "$ROOT"/files/bin/* "$ROOT"/tests/*.sh; do
    [[ -f "$script" ]] || continue
    case "$(head -n1 -- "$script")" in
        *python*) check=(python3 -c 'import ast, sys; ast.parse(open(sys.argv[1]).read())') ;;
        *) check=(bash -n); bash_scripts+=("$script") ;;
    esac
    if ! "${check[@]}" "$script"; then
        fail "Syntax: ${script#"$ROOT"/}"
        syntax_failures=$((syntax_failures + 1))
    fi
done
((syntax_failures == 0)) && pass "Script syntax"

# ShellCheck is a Haskell program; run it from Nix rather than installing the
# Haskell runtime with pacman.
if [[ "${DOTFILES_SKIP_SHELLCHECK:-0}" != 1 ]] && command -v nix >/dev/null 2>&1; then
    if nix run nixpkgs#shellcheck -- -S warning "${bash_scripts[@]}"; then
        pass "shellcheck"
    else
        fail "shellcheck"
    fi
fi

# Every file in the active Home Manager generation must be what is deployed.
if [[ "${DOTFILES_SKIP_HM:-0}" != 1 ]]; then
    HM_GEN="$(readlink -f -- "$HOME/.local/state/nix/profiles/home-manager" 2>/dev/null || true)"
    if [[ -z "$HM_GEN" || ! -d "$HM_GEN/home-files" ]]; then
        fail "no active Home Manager generation"
    else
        managed=0 drifted=()
        while IFS= read -r -d '' file; do
            rel="${file#"$HM_GEN/home-files/"}"
            managed=$((managed + 1))
            [[ "$(readlink -f -- "$HOME/$rel" 2>/dev/null)" == "$(readlink -f -- "$file")" ]] ||
                drifted+=("$rel")
        done < <(find "$HM_GEN/home-files/" \( -type l -o -type f \) -print0)
        if ((${#drifted[@]})); then
            fail "not deployed from the current generation: ${drifted[*]}"
        else
            pass "all $managed Home Manager files deployed"
        fi
    fi
fi

# Ownership: shells, man, and Python come from pacman, never from a Nix or
# hand-copied binary earlier in PATH.
for tool in bash fish man python3; do
    if [[ "$(command -v "$tool")" == /usr/bin/"$tool" ]]; then
        pass "$tool from pacman"
    else
        fail "$tool resolves to $(command -v "$tool" || echo nothing), not /usr/bin/$tool"
    fi
done

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
