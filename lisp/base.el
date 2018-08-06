;;; base.el --- Base configuration -*- lexical-binding: t -*-

;;; Commentary:
;; Setting sane defaults.

;;; Code:

(require 'base-vars)

(defvar my-init-time nil
  "The time it took, in seconds, for Emacs to initialize.")

(eval-when-compile
  (defvar desktop-dirname)
  (defvar dired-use-ls-dired)
  (defvar x-gtk-use-system-tooltips))

;;;
;; Settings

;; UTF-8 as the default coding system
(set-charset-priority 'unicode)
(prefer-coding-system        'utf-8)
(set-terminal-coding-system  'utf-8)
(set-keyboard-coding-system  'utf-8)
(set-selection-coding-system 'utf-8)
(setq locale-coding-system   'utf-8)
(setq-default buffer-file-coding-system 'utf-8)
(setq default-process-coding-system '(utf-8-unix . utf-8-unix))

(setq-default
 max-specpdl-size 32000         ; Handle code with excessive variable bindings (mainly lsp-mode)
 ad-redefinition-action 'accept ; Silence advised function warnings
 apropos-do-all t               ; Make `apropos' search for more stuff
 compilation-always-kill t      ; Kill compilation process before starting another
 compilation-ask-about-save nil ; Save all buffers on `compile'
 compilation-scroll-output t
 confirm-nonexistent-file-or-buffer t
 enable-recursive-minibuffers t
 debug-on-error (and (not noninteractive) my-debug-mode)
 ;; Update UI less often
 idle-update-delay 2
 ;; Keep the point out of the minibuffer
 minibuffer-prompt-properties
 '(read-only t point-entered minibuffer-avoid-prompt face minibuffer-prompt)
 ;; History & backup settings
 auto-save-default t            ; Enable auto-save
 auto-save-visited-file-name t  ; Auto-save to the same file
 create-lockfiles nil
 make-backup-files nil
 history-delete-duplicates t
 history-length 500
 ;; Don't save abbrevs
 save-abbrevs 'silently
 ;; Files
 source-directory                  (expand-file-name "emacs" "~/src/git.sv.gnu.org")
 abbrev-file-name                  (concat my-data-dir "abbrev.el")
 auto-save-list-file-name          (concat my-cache-dir "autosave")
 backup-directory-alist            (list (cons "." (concat my-cache-dir "backup/")))
 desktop-dirname                   my-data-dir
 desktop-path                      (list desktop-dirname)
 eshell-directory-name             (concat my-data-dir "eshell/")
 eshell-history-file-name          (concat my-data-dir "eshell-history")
 pcache-directory                  (concat my-cache-dir "pcache/")
 semanticdb-default-save-directory (concat my-cache-dir "semanticdb/")
 server-auth-dir                   (concat my-cache-dir "server/")
 shared-game-score-directory       (concat my-data-dir "shared-game-score/")
 tramp-auto-save-directory         (concat my-cache-dir "tramp-auto-save/")
 tramp-backup-directory-alist      backup-directory-alist
 tramp-persistency-file-name       (concat my-cache-dir "tramp-persistency.el")
 url-cache-directory               (concat my-cache-dir "url/")
 url-configuration-directory       (concat my-data-dir "url/"))

;; Move custom defs out of init.el
(setq custom-file (concat my-data-dir "custom.el"))

;; OS-specific
(when (memq window-system '(mac ns))
  (setq dired-use-ls-dired nil)
  (dolist (item (list
                 "/usr/local/bin"
                 (expand-file-name "~/go/bin")
                 (expand-file-name "~/.opam/system/bin")
                 (expand-file-name "~/.local/bin")
                 ".git/safe/../../bin"))
    (setenv "PATH" (concat item ":" (getenv "PATH")))
    (setq exec-path (push item exec-path))))

(when (eq window-system 'x)
  (setq x-gtk-use-system-tooltips nil
        ;; Clipboard
        x-select-request-type '(UTF8_STRING COMPOUND_TEXT TEXT STRING)
        ;; Use shared clipboard
        select-enable-clipboard t
        select-enable-primary t))

;;;
;; Initialize

(eval-and-compile
  (require 'cl-lib)
  (require 'base-package)

  (eval-when-compile
    (+packages-initialize))

  (setq load-path (eval-when-compile load-path)
        custom-theme-load-path (eval-when-compile custom-theme-load-path))

  (require 'base-lib))

(require 'server)
(unless (server-running-p)
  (server-start))

;;;
;; Bootstrap

(unless noninteractive
  (require 'base-keybinds)
  (require 'base-popups)
  (require 'base-projects)
  (require 'base-modeline)
  (require 'base-editor)
  (require 'base-ui))

(provide 'base)
;;; base.el ends here
