;;; init.el --- Emacs Configuration -*- lexical-binding: t; -*-
;;; Commentary:
;; Converted from NixOS configuration for CachyOS/Arch Linux

;;; Code:

(require 'cl-lib)

(defconst my/emacs-state-root
  (file-name-as-directory
   (expand-file-name "emacs" (or (getenv "XDG_STATE_HOME") "~/.local/state"))))
(defconst my/emacs-data-root
  (file-name-as-directory
   (expand-file-name "emacs" (or (getenv "XDG_DATA_HOME") "~/.local/share"))))
(defconst my/emacs-cache-root
  (file-name-as-directory
   (expand-file-name "emacs" (or (getenv "XDG_CACHE_HOME") "~/.cache"))))

(dolist (directory (list my/emacs-state-root my/emacs-data-root my/emacs-cache-root))
  (make-directory directory t)
  (set-file-modes directory #o700))

(setq package-user-dir
      (or (getenv "EMACS_PACKAGE_DIR")
          (expand-file-name "elpa" my/emacs-data-root))
      custom-file (expand-file-name "custom.el" my/emacs-state-root))

;; ============================================================================
;; PACKAGE MANAGEMENT SETUP
;; ============================================================================

;; Set up package repositories
(require 'package)
(setq package-archives '(("melpa" . "https://melpa.org/packages/")
                         ("gnu" . "https://elpa.gnu.org/packages/")))
(package-initialize)

;; Bootstrap use-package
(unless (package-installed-p 'use-package)
  (package-refresh-contents)
  (package-install 'use-package))

(require 'use-package)
(setq use-package-always-ensure t)

;; ============================================================================
;; BASIC UI SETTINGS
;; ============================================================================

;; Load required packages early to avoid free variable warnings
(require 'display-line-numbers)
(require 'dired)

;; Basic UI settings
(setq ring-bell-function 'ignore
      evil-insert-state-cursor 'box
      initial-buffer-choice t
      display-line-numbers-type 'relative)

(setq dired-dwim-target t)
(winner-mode 1)
(menu-bar-mode 0)
(tool-bar-mode 0)
(scroll-bar-mode 0)
(column-number-mode 1)
(fringe-mode 0)
(global-display-line-numbers-mode)
(set-face-attribute 'default nil :height 170)

;; The daemon starts with a short PATH. Let Emacs and its subprocesses find
;; tools installed per user: Rust tools from rustup, and the coding agents that
;; aside drives (OpenCode, Cline, and the Claude Code and Codex ACP adapters).
(dolist (dir '("~/.cargo/bin" "~/.local/bin" "~/.opencode/bin"
               "~/.local/share/pnpm/bin"))
  (let ((dir (expand-file-name dir)))
    (add-to-list 'exec-path dir)
    (setenv "PATH" (concat dir path-separator (getenv "PATH")))))

;; IDO mode
(ido-mode 1)
(ido-everywhere 1)

;; Recovery files are enabled but centralized. Projects never receive `~`,
;; `#...#`, `.#...`, undo-tree, or Custom artifacts.
(let ((backup-dir (expand-file-name "backups/" my/emacs-state-root))
      (auto-save-dir (expand-file-name "auto-save/" my/emacs-state-root))
      (lock-dir (expand-file-name "locks/" my/emacs-state-root))
      (undo-dir (expand-file-name "undo-tree/" my/emacs-state-root)))
  (dolist (directory (list backup-dir auto-save-dir lock-dir undo-dir))
    (make-directory directory t)
    (set-file-modes directory #o700))
  (setq backup-directory-alist `(("." . ,backup-dir))
        auto-save-file-name-transforms `((".*" ,auto-save-dir sha256))
        auto-save-list-file-prefix (expand-file-name "sessions/" auto-save-dir)
        lock-file-name-transforms `((".*" ,lock-dir sha256))
        undo-tree-history-directory-alist `(("." . ,undo-dir))))

(setq-default make-backup-files t
              auto-save-default t
              compile-command "")
(setq backup-by-copying t
      version-control t
      kept-new-versions 10
      kept-old-versions 2
      delete-old-versions t
      auto-save-timeout 20
      auto-save-interval 200)

;; ============================================================================
;; COMPILATION SETTINGS
;; ============================================================================

;; Compilation functions
(defun my-compile-without-history ()
  "Run compile command with an empty initial prompt but preserve history."
  (interactive)
  (let ((current-prefix-arg '(4))
        (compilation-read-command t))
    (setq-default compile-command "")
    (setq compile-command "")
    (call-interactively 'compile)
    (with-current-buffer "*compilation*"
      (evil-normal-state))))

(defun my-recompile ()
  "Recompile and ensure normal mode in compilation buffer."
  (interactive)
  (recompile)
  (with-current-buffer "*compilation*"
    (evil-normal-state)))

(advice-add 'recompile :after
            (lambda (&rest _)
              (with-current-buffer "*compilation*"
                (evil-normal-state))))

(advice-add 'compile :around
            (lambda (orig-fun &rest args)
              (let ((compile-command ""))
                (apply orig-fun args))))

(global-set-key [remap compile] 'my-compile-without-history)

;; Compilation window settings
(setq display-buffer-alist
      `((,(rx bos "*compilation*" eos)
         (display-buffer-reuse-window display-buffer-at-bottom)
         (window-height . 0.4)
         (preserve-size . (nil . t))
         (select . t))))

(setq compilation-finish-functions
      (list (lambda (_buf _str)
              (let ((win (get-buffer-window "*compilation*")))
                (when win
                  (select-window win)
                  (evil-normal-state))))))

;; ============================================================================
;; BUFFER AND FILE UTILITIES
;; ============================================================================

;; Buffer cleanup functions
(defun my/cleanup-deleted-file-buffers ()
  "Close buffers of files that no longer exist."
  (dolist (buf (buffer-list))
    (let ((filename (buffer-file-name buf)))
      (when (and filename
                 (not (file-exists-p filename)))
        (kill-buffer buf)))))

;; Dired create-file helper
(defun my/dired-create-file (filename)
  "Create a new file in the current dired directory."
  (interactive
   (list (read-string "Create file: " (dired-current-directory))))
  (let* ((filepath (expand-file-name filename (dired-current-directory)))
         (dir (file-name-directory filepath)))
    (when (and (not (file-exists-p dir))
               (yes-or-no-p (format "Directory %s does not exist. Create it? " dir)))
      (make-directory dir t))
    (when (file-exists-p dir)
      (write-region "" nil filepath)
      (dired-add-file filepath)
      (revert-buffer)
      (dired-goto-file (expand-file-name filepath)))))

;; ============================================================================
;; PACKAGE CONFIGURATIONS
;; ============================================================================

;; Evil Mode
(use-package evil
  :ensure t
  :init
  ;; Must be set *before* Evil loads
  (setq evil-want-integration t
        evil-want-keybinding nil
        evil-want-C-u-scroll t
        evil-want-C-i-jump t
        evil-undo-system 'undo-tree)
  :config
  ;; Actually enable Evil
  (evil-mode 1)

  ;; Make delete operations use the black hole register
  (evil-define-operator evil-delete-blackhole (beg end type register yank-handler)
    "Delete text from BEG to END using black hole register."
    (interactive "<R><x><y>")
    (evil-delete beg end type ?_ yank-handler))

  ;; Remap d to use black hole register
  (define-key evil-normal-state-map "d" 'evil-delete-blackhole)
  (define-key evil-visual-state-map "d" 'evil-delete-blackhole)

  ;; Evil ex commands
  (evil-ex-define-cmd "Man" 'man)
  (evil-set-initial-state 'Man-mode 'normal)
  (evil-ex-define-cmd "compile" 'my-compile-without-history)
  (evil-ex-define-cmd "recompile" 'my-recompile)

  ;; Evil key bindings
  (evil-define-key '(normal insert) 'global (kbd "C-v") 'evil-paste-after)
  (evil-define-key '(normal insert) 'global (kbd "C-S-v") 'evil-paste-after)
  (evil-define-key 'normal dired-mode-map (kbd "RET") 'dired-find-file)

  (with-eval-after-load 'dired
  (evil-set-initial-state 'dired-mode 'emacs)  ; This will use Emacs default keybindings
  (define-key dired-mode-map (kbd "%") 'my/dired-create-file)
  (define-key dired-mode-map ":"
    (lambda ()
      (interactive)
      (evil-ex)))
  (define-key dired-mode-map "/" 'evil-search-forward)))

;; Undo-tree
(use-package undo-tree
  :ensure t
  :config
  (global-undo-tree-mode))

;; Direnv
(use-package direnv
  :ensure t
  :config
  (direnv-mode))

;; Gruber-darker theme
(use-package gruber-darker-theme
  :ensure t
  :config
  (load-theme 'gruber-darker t)
  ;; The 2023 theme stores nil foreground/background values. Emacs 30 warns
  ;; once per affected face on every new frame. Sanitize the registered theme
  ;; settings in memory, preserving package updates and the theme's appearance.
  (cl-labels ((sanitize-colors
               (form)
               (when (consp form)
                 (let ((tail form))
                   (while (consp tail)
                     (when (and (memq (car tail) '(:foreground :background))
                                (consp (cdr tail))
                                (null (cadr tail)))
                       (setcar (cdr tail) 'unspecified))
                     (sanitize-colors (car tail))
                     (setq tail (cdr tail)))))))
    (let ((settings (copy-tree (get 'gruber-darker 'theme-settings))))
      (sanitize-colors settings)
      (put 'gruber-darker 'theme-settings settings)
      ;; Re-register per-face theme specs from the corrected settings. Merely
      ;; changing the theme symbol is insufficient: new frames use these
      ;; per-face properties.
      (disable-theme 'gruber-darker)
      (enable-theme 'gruber-darker))))

;; Zig mode
(use-package zig-mode
  :ensure t
  :mode ("\\.zig\\'" . zig-mode))

;; Nix mode
(use-package nix-mode
  :ensure t
  :mode ("\\.nix\\'" . nix-mode))

;; Rust mode
(use-package rust-mode
  :ensure t
  :mode ("\\.rs\\'" . rust-mode))

;; Python mode
(use-package python-mode
  :ensure t
  :mode ("\\.py\\'" . python-mode))

;; C# mode
(use-package csharp-mode
  :ensure t
  :mode ("\\.cs\\'" . csharp-mode))

;; Go mode
(use-package go-mode
  :ensure t
  :mode ("\\.go\\'" . go-mode)
  :config
  ;; Set up gofmt on save
  (add-hook 'before-save-hook 'gofmt-before-save)

  ;; Set tab width for Go files
  (add-hook 'go-mode-hook
            (lambda ()
              (setq tab-width 4)
              (setq indent-tabs-mode t))))

;; VTerm
(use-package vterm
  :ensure t
  :config
  ;; Keep shell enhancers out of vterm.
  (setq vterm-environment '("BLESH_AUTO_DISABLE=1"
                            "INSIDE_EMACS=vterm"))

  ;; Custom vterm function
  (defun my/vterm ()
    "Open vterm with specific environment variables set."
    (interactive)
    (let ((vterm-shell (getenv "SHELL")))
      (vterm))))

(global-set-key (kbd "C-c t") 'my/vterm)

;; Magit
(use-package magit
  :ensure t)

;; aside: a popup for coding agents (OpenCode, Claude Code, Codex, Cline).
;; Update with M-x package-vc-upgrade RET aside.
(use-package aside
  :vc (:url "https://github.com/nottzaid/aside")
  :bind (("C-c o" . aside)
         ("C-c h" . aside-toggle)
         ("C-c r" . aside-resume)))

;; ============================================================================
;; ASSEMBLY LANGUAGE MODES
;; ============================================================================

;; FASM Mode configuration
;; Add the directory containing fasm-mode.el to load-path
(add-to-list 'load-path "~/.emacs.d/lisp/")

;; Load fasm-mode only if the file exists
(if (file-exists-p "~/.emacs.d/lisp/fasm-mode.el")
    (progn
      (require 'fasm-mode)
      ;; Associate .fasm files with fasm-mode
      (add-to-list 'auto-mode-alist '("\\.fasm\\'" . fasm-mode))
      ;; Setup whitespace handling for fasm-mode
      (add-hook 'fasm-mode-hook
                (lambda ()
                  ;; Enable whitespace mode
                  (whitespace-mode 1)
                  ;; Delete trailing whitespace on save
                  (add-to-list 'write-file-functions 'delete-trailing-whitespace))))
  (message "Warning: fasm-mode.el not found"))

;; NASM Mode configuration
(use-package nasm-mode
  :ensure t
  :mode ("\\.nasm\\'" . nasm-mode)
  :config
  (add-hook 'nasm-mode-hook
            (lambda ()
              ;; Enable whitespace mode
              (whitespace-mode 1)
              ;; Delete trailing whitespace on save
              (add-to-list 'write-file-functions 'delete-trailing-whitespace))))

;; Function to switch between ASM modes based on content
(defun my/detect-asm-mode ()
  "Detect whether to use FASM or NASM mode based on file content."
  (interactive)
  (when (string-match "\\.asm\\'" (buffer-file-name))
    ;; Check for NASM-specific format indicators in the first few lines
    (save-excursion
      (goto-char (point-min))
      (if (re-search-forward "\\(section\\|segment\\|global\\|extern\\)\\s-+[._a-zA-Z0-9]+" nil t)
          (nasm-mode)
        (fasm-mode)))))

;; Associate .asm files with the detector function
(add-to-list 'auto-mode-alist '("\\.asm\\'" . my/detect-asm-mode))

;; Commands to explicitly switch between modes
(defun my/switch-to-fasm-mode ()
  "Switch current buffer to FASM mode."
  (interactive)
  (fasm-mode)
  (message "Switched to FASM mode"))

(defun my/switch-to-nasm-mode ()
  "Switch current buffer to NASM mode."
  (interactive)
  (nasm-mode)
  (message "Switched to NASM mode"))

(defun my/show-current-mode ()
  "Display the current major mode."
  (interactive)
  (message "Current mode: %s" major-mode))

;; Add key bindings for switching between modes
(global-set-key (kbd "C-c f") 'my/switch-to-fasm-mode)
(global-set-key (kbd "C-c n") 'my/switch-to-nasm-mode)

(global-set-key (kbd "C-c m") 'my/show-current-mode)

;; ============================================================================
;; SCRATCH MAGIC POLISH
;; ============================================================================

;; Preferred API key setup:
;; - Shell env var: GEMINI_API_KEY
;; - Or put this in ~/.emacs.d/local-secrets.el (untracked):
;;   (setq scratch-magic-api-key "YOUR_GEMINI_API_KEY")
(let ((my/local-secrets-file (expand-file-name "local-secrets.el" user-emacs-directory)))
  (when (file-readable-p my/local-secrets-file)
    (load my/local-secrets-file nil t)))

;; Optional model override (default is already gemini-3-flash-preview):
;; (setq scratch-magic-model "gemini-3-flash-preview")

(when (require 'scratch-magic-polish nil t)
  ;; Local-only binding in *scratch* so existing global mappings remain intact.
  (defun my/scratch-magic-bind-key ()
    "Bind C-c m to scratch magic only in *scratch*."
    (when (and (derived-mode-p 'lisp-interaction-mode)
               (string= (buffer-name) "*scratch*"))
      (local-set-key (kbd "C-c m") #'scratch-magic-polish)))
  (add-hook 'lisp-interaction-mode-hook #'my/scratch-magic-bind-key)
  ;; Apply immediately when reloading config with an already-open *scratch*.
  (when (get-buffer "*scratch*")
    (with-current-buffer "*scratch*"
      (my/scratch-magic-bind-key))))

(when (file-readable-p custom-file)
  (load custom-file nil t))

;;; init.el ends here
