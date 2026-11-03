;;; early-init.el --- Early Initialization -*- lexical-binding: t; -*-
;;; Commentary:
;; This file is loaded before init.el and package initialization

;;; Code:

(defconst my/emacs-data-root
  (file-name-as-directory
   (expand-file-name "emacs" (or (getenv "XDG_DATA_HOME") "~/.local/share"))))
(defconst my/emacs-cache-root
  (file-name-as-directory
   (expand-file-name "emacs" (or (getenv "XDG_CACHE_HOME") "~/.cache"))))

(setq package-user-dir
      (or (getenv "EMACS_PACKAGE_DIR")
          (expand-file-name "elpa" my/emacs-data-root)))

(when (fboundp 'startup-redirect-eln-cache)
  (startup-redirect-eln-cache (expand-file-name "eln-cache" my/emacs-cache-root)))

;; go-mode's optional Eglot/lsp-mode helpers are not declared to the compiler
;; in the current upstream release.  Keep this one small mode on byte-code
;; until upstream adds the declarations, avoiding misleading native warnings.
(defvar native-comp-jit-compilation-deny-list)
(with-eval-after-load 'comp
  (add-to-list 'native-comp-jit-compilation-deny-list
               "\\(?:^\\|/\\)go-mode\\.el\\'"))

;; Disable package.el initialization so use-package can control it
(setq package-enable-at-startup nil)

;; Pre-load Evil settings
(setq evil-want-integration t
      evil-want-keybinding nil
      evil-want-C-u-scroll t
      evil-want-C-i-jump t
      evil-undo-system 'undo-tree)

;;; early-init.el ends here
