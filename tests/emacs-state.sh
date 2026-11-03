#!/usr/bin/env bash

set -Eeuo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
ORIGINAL_HOME="$HOME"
TEST_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-emacs.XXXXXX")"
TEST_HOME="$TEST_ROOT/home"
PROJECT="$ORIGINAL_HOME/.local/state/dotfiles-tests/emacs-$$"
SERVER="dotfiles-emacs-test-$$"
PACKAGE_DIR="${EMACS_PACKAGE_DIR:-$ORIGINAL_HOME/.local/share/emacs/elpa}"

if [[ ! -d "$PACKAGE_DIR" && -d "$ORIGINAL_HOME/.emacs.d/elpa" ]]; then
    PACKAGE_DIR="$ORIGINAL_HOME/.emacs.d/elpa"
fi
[[ -d "$PACKAGE_DIR" ]] || {
    printf 'emacs-state: package directory is missing; install Emacs packages first\n' >&2
    exit 1
}

client() {
    HOME="$TEST_HOME" emacsclient -s "$SERVER" "$@"
}

cleanup() {
    client --eval '(kill-emacs)' >/dev/null 2>&1 || true
    rm -rf -- "$TEST_ROOT" "$PROJECT"
}
trap cleanup EXIT

mkdir -p "$TEST_HOME/.emacs.d/lisp" "$PROJECT"
ln -s "$ROOT/home/.emacs.d/init.el" "$TEST_HOME/.emacs.d/init.el"
ln -s "$ROOT/home/.emacs.d/early-init.el" "$TEST_HOME/.emacs.d/early-init.el"
for file in "$ROOT"/home/.emacs.d/lisp/*.el; do
    ln -s "$file" "$TEST_HOME/.emacs.d/lisp/${file##*/}"
done
printf 'baseline\n' >"$PROJECT/sample.txt"

HOME="$TEST_HOME" \
XDG_STATE_HOME="$TEST_HOME/.local/state" \
XDG_DATA_HOME="$TEST_HOME/.local/share" \
XDG_CACHE_HOME="$TEST_HOME/.cache" \
EMACS_PACKAGE_DIR="$PACKAGE_DIR" \
emacs --daemon="$SERVER" >"$TEST_ROOT/daemon.out" 2>"$TEST_ROOT/daemon.err"

for _ in {1..100}; do
    client --eval t >/dev/null 2>&1 && break
    sleep 0.05
done
client --eval t >/dev/null 2>&1 || {
    cat "$TEST_ROOT/daemon.err" >&2
    exit 1
}

result="$(client --eval "
  (let* ((file \"$PROJECT/sample.txt\") auto lock backup)
    (find-file file)
    (goto-char (point-max))
    (insert \"unsaved recovery line\\n\")
    (setq auto (make-auto-save-file-name))
    (do-auto-save t)
    (unless (and (file-exists-p auto)
                 (with-temp-buffer
                   (insert-file-contents auto)
                   (search-forward \"unsaved recovery line\" nil t)))
      (error \"auto-save recovery content missing\"))
    (setq lock (make-lock-file-name file))
    (unless (file-symlink-p lock)
      (error \"central lock file missing\"))
    (save-buffer)
    (setq backup (file-newest-backup file))
    (unless (and backup (file-exists-p backup))
      (error \"central backup missing\"))
    (list auto lock backup)))")"
[[ "$result" != *"*ERROR*"* ]] || {
    printf '%s\n' "$result" >&2
    exit 1
}

state_root="$TEST_HOME/.local/state/emacs"
[[ "$(stat -c %a "$state_root")" == 700 ]]
[[ -n "$(find "$state_root/backups" -type f -print -quit)" ]]
[[ -n "$(find "$state_root/undo-tree" -type f -print -quit)" ]]
[[ "$(find "$PROJECT" -mindepth 1 -maxdepth 1 -printf '%f\n')" == sample.txt ]]

if [[ -n "${DISPLAY:-}" ]]; then
    frame_result="$(client --eval '
      (let* ((messages (get-buffer-create "*Messages*"))
             (start (with-current-buffer messages (point-max)))
             (frame (make-frame-on-display (getenv "DISPLAY")
                                           (quote ((visibility . nil)))))
             result)
        (delete-frame frame)
        (setq result (with-current-buffer messages
                       (buffer-substring-no-properties start (point-max))))
        (if (string-match-p "nil value is invalid" result) result "none"))')"
    [[ "$frame_result" == '"none"' ]] || {
        printf 'theme frame warnings: %s\n' "$frame_result" >&2
        exit 1
    }
else
    printf 'SKIP graphical frame test: DISPLAY is unset\n'
fi

printf 'PASS Emacs recovery is centralized and project-clean\n'
