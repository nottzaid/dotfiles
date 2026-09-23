#!/usr/bin/env bash

set -Eeuo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_PACKAGES=0
INSTALL_STREAMING=0
INSTALL_SYSTEM=0

usage() {
    cat <<'EOF'
Usage: ./install.sh [options]

Apply the Home Manager configuration (flake at the repository root), which
owns all shell/desktop/editor dotfiles. Options add what Home Manager
deliberately does not own: pacman packages and root-level configuration.

  --packages     install the desktop package manifests (pacman + AUR)
  --streaming    install the yt-stream-workspace package manifest and config
  --system       apply root-level configuration (system/apply.sh, via sudo)
  --full         all of the above
  --help         show this help

Set DOTFILES_SKIP_HM=1 to skip the Home Manager switch (used by tests
that run against a disposable HOME without nix).
EOF
}

while (($#)); do
    case "$1" in
        --packages) INSTALL_PACKAGES=1 ;;
        --streaming) INSTALL_STREAMING=1 ;;
        --system) INSTALL_SYSTEM=1 ;;
        --full)
            INSTALL_PACKAGES=1
            INSTALL_STREAMING=1
            INSTALL_SYSTEM=1
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            printf 'install.sh: unknown option: %s\n' "$1" >&2
            usage >&2
            exit 2
            ;;
    esac
    shift
done

note() {
    printf 'dotfiles: %s\n' "$*"
}

die() {
    note "$*" >&2
    exit 1
}

install_template() {
    local source="$1" destination="$2"

    [[ -e "$source" ]] || die "missing repository template: $source"
    if [[ -e "$destination" || -L "$destination" ]]; then
        note "preserved ${destination#"$HOME"/}"
        return 0
    fi
    mkdir -p -- "$(dirname -- "$destination")"
    install -m 0600 -- "$source" "$destination"
    note "created ${destination#"$HOME"/} from template"
}

read_manifest() {
    sed -e 's/[[:space:]]*#.*$//' -e '/^[[:space:]]*$/d' "$1"
}

install_pacman_manifest() {
    local manifest="$1"
    local -a packages=() missing=()
    mapfile -t packages < <(read_manifest "$manifest")
    ((${#packages[@]})) || return 0
    if [[ "${DOTFILES_SKIP_PACKAGE_INSTALL:-0}" == 1 ]]; then
        note "skipped package installation for ${manifest#"$ROOT"/}"
        return 0
    fi
    command -v pacman >/dev/null 2>&1 || die "package installation requires pacman"
    mapfile -t missing < <(pacman -T "${packages[@]}" 2>/dev/null || true)
    if ((${#missing[@]} == 0)); then
        note "packages already satisfied: ${manifest#"$ROOT"/}"
        return 0
    fi
    sudo pacman -S --needed "${missing[@]}"
}

install_aur_manifest() {
    local manifest="$1"
    local -a packages=() missing=()
    mapfile -t packages < <(read_manifest "$manifest")
    [[ "${DOTFILES_SKIP_PACKAGE_INSTALL:-0}" != 1 ]] || return 0
    mapfile -t missing < <(pacman -T "${packages[@]}" 2>/dev/null || true)
    ((${#missing[@]})) || return 0
    command -v paru >/dev/null 2>&1 || die "AUR packages need paru: ${missing[*]}"
    paru -S --needed "${missing[@]}"
}

git -C "$ROOT" submodule update --init --recursive

if ((INSTALL_PACKAGES)); then
    install_pacman_manifest "$ROOT/packages/desktop.txt"
    install_aur_manifest "$ROOT/packages/aur.txt"
fi
if ((INSTALL_STREAMING)); then
    install_pacman_manifest "$ROOT/packages/streaming.txt"
fi
if ((INSTALL_SYSTEM)); then
    if [[ "${DOTFILES_SKIP_SYSTEM:-0}" == 1 ]]; then
        note "skipped system configuration (DOTFILES_SKIP_SYSTEM=1)"
    else
        sudo "$ROOT/system/apply.sh"
    fi
fi

# Shell, desktop, and editor configuration is owned by Home Manager (flake at
# the repository root). Nix lives outside the default PATH in non-login
# shells, so make its profile visible before probing (appended: never shadow
# the system).
case ":${PATH}:" in
    *:"$HOME/.nix-profile/bin":*) ;;
    *) PATH="$PATH:$HOME/.nix-profile/bin" ;;
esac
export PATH
if [[ "${DOTFILES_SKIP_HM:-0}" == 1 ]]; then
    note "skipped home-manager switch (DOTFILES_SKIP_HM=1)"
elif command -v home-manager >/dev/null 2>&1; then
    home-manager switch --flake "$ROOT"
elif command -v nix >/dev/null 2>&1; then
    # Bootstrap with the Home Manager revision pinned in flake.lock.
    nix run --inputs-from "$ROOT" home-manager -- switch --flake "$ROOT"
else
    die "home-manager switch requires nix: install nix, then rerun"
fi

if ((INSTALL_STREAMING)); then
    install_template "$ROOT/components/yt-stream-workspace/config.example" \
        "$HOME/.config/yt-stream-workspace/config"
fi

# Make the Home Manager login environment available to newly started user
# services now; the next login establishes it naturally for the session.
# The generated script is not `set -u` clean, so relax nounset around it.
if [[ -f "$HOME/.nix-profile/etc/profile.d/hm-session-vars.sh" ]]; then
    set +u
    # shellcheck disable=SC1091
    . "$HOME/.nix-profile/etc/profile.d/hm-session-vars.sh"
    set -u
fi
if [[ "${DOTFILES_SKIP_SESSION_IMPORT:-0}" != 1 ]]; then
    systemctl --user import-environment PATH 2>/dev/null || true
fi

note "installation complete; run ./verify.sh"
