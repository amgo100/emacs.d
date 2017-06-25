;;; base-vars.el --- Base variables

;;; Commentary:
;; Customization through variables.

;;; Code:

;;;
;; Base
(defvar my-debug-mode (or (getenv "DEBUG") init-file-debug)
  "Debug mode, enable through DEBUG=1 or use --debug-init.")

(defvar my-emacs-dir user-emacs-directory
  "The path to this .emacs.d directory.")

(defvar my-elisp-dir (concat user-emacs-directory "elisp/")
  "The path to the elisp files.")

(defvar my-cache-dir
  (if (getenv "XDG_CACHE_HOME")
      (concat (getenv "XDG_CACHE_HOME") "/emacs/")
    (expand-file-name "~/.cache/emacs/"))
  "Use XDG-based cache directory.")

(defvar my-data-dir
  (if (getenv "XDG_DATA_HOME")
      (concat (getenv "XDG_DATA_HOME") "/emacs/")
    (expand-file-name "~/.local/share/emacs/"))
  "Use XDG-based data directory.")

(defvar my-packages-dir (concat my-data-dir "packages/")
  "Use XDG-based packages directory.")

;;;
;; UI
(defvar my-fringe-width 12
  "The fringe width to use.")

(defvar my-completion-system 'ivy
  "The completion system to use.")

;;;
;; Theme
(defvar my-theme 'tao-yang
  "The color theme to use.")

(defvar my-default-font-height 140
  "The default font height to use.")

(defvar my-font "Fira Mono"
  "The monospace font to use.")

(defvar my-variable-pitch-font "Fira Sans Book"
  "The regular font to use.")

(defvar my-unicode-font "Noto Mono"
  "Fallback font for unicode glyphs.")

(defvar my-evil-default-mode-color "#AB47BC"
  "Default mode color for Evil states.")

(defvar my-evil-mode-color-list
  `((normal   . "#4CAF50")
    (emacs    . "#2196F3")
    (insert   . "#2196F3")
    (replace  . "#F44336")
    (visual   . "#FF9800"))
  "Mode color corresponding to Evil state.")

(provide 'base-vars)
;;; base-vars.el ends here