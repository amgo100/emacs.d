;;; base-ui.el --- UI configuration -*- lexical-binding: t; -*-

;;; Commentary:
;; The behavior of things.

;;; Code:

(eval-when-compile
  (require 'base-vars)
  (require 'base-package)
  (require 'base-lib))

;;;
;; Settings

(setq-default
 ;; Disable bidirectional text for tiny performance boost
 bidi-display-reordering nil
 ;; Disable non selected window highlight
 cursor-in-non-selected-windows nil
 highlight-nonselected-windows nil
 display-line-number-width 3
 blink-matching-paren nil
 frame-inhibit-implied-resize t
 redisplay-dont-pause t
 jit-lock-defer-time nil
 jit-lock-stealth-nice 0.1
 jit-lock-stealth-time 0.2
 jit-lock-stealth-verbose nil
 max-mini-window-height 0.3
 mouse-yank-at-point t           ; Middle-click paste at point, not at click
 resize-mini-windows 'grow-only  ; Minibuffer resizing
 show-help-function nil          ; Hide :help-echo text
 split-width-threshold nil       ; Favor horizontal splits
 use-dialog-box nil              ; Avoid GUI
 visible-cursor nil
 x-stretch-cursor nil
 uniquify-buffer-name-style 'forward
 ;; Scrolling
 hscroll-margin 1
 hscroll-step 1
 scroll-conservatively 1001
 scroll-margin 0
 scroll-preserve-screen-position t
 ;; Margins
 left-margin-width 1
 right-margin-width 1
 ;; Fringes
 fringes-outside-margins t
 indicate-buffer-boundaries 'right
 indicate-empty-lines t
 visual-line-fringe-indicators '(left-curly-arrow right-curly-arrow)
 ;; `pos-tip' defaults
 pos-tip-internal-border-width 6
 pos-tip-border-width 1
 ;; No blinking or beeping
 ring-bell-function #'ignore
 visible-bell nil
 calendar-week-start-day 1)

;; y/n instead of yes/no
(setq-default confirm-kill-emacs 'y-or-n-p)
(fset #'yes-or-no-p #'y-or-n-p)

;; Tooltips in echo area
(tooltip-mode 0)

(add-graphic-hook
 (menu-bar-mode 0)
 (tool-bar-mode 0)
 (scroll-bar-mode 0))

;; Transparent non-graphic background color
(add-terminal-hook (set-face-background 'default nil))

;; Setup border
(push (cons 'internal-border-width my-fringe-width) default-frame-alist)

;; Standardize fringe width
(push (cons 'left-fringe  my-fringe-width) default-frame-alist)
(push (cons 'right-fringe my-fringe-width) default-frame-alist)
(add-hook! '(emacs-startup minibuffer-setup)
           (set-window-fringes (minibuffer-window) 0 0 nil))

;; Text scaling
(defadvice text-scale-increase (around all-buffers (arg) activate)
  "Text scale across all buffers."
  (dolist (buffer (buffer-list))
    (with-current-buffer buffer ad-do-it)))

;; Visual line wrapping
(diminish 'visual-line-mode)
(add-hooks-pair '(text-mode
                  prog-mode
                  Man-mode)
                'visual-line-mode)

;;;
;; Built-ins

;; comint
(req-package comint
  :loader :built-in
  :init
  (add-to-list 'comint-output-filter-functions 'ansi-color-process-output)
  (add-to-list 'comint-output-filter-functions 'comint-strip-ctrl-m))

;; Compilation
(req-package compile
  :loader :built-in
  :hook (compilation-filter . +colorize-compilation-buffer)
  :init
  (autoload 'ansi-color-apply-on-region "ansi-color")
  ;; Filter ANSI escape codes in compilation-mode output
  (defun +colorize-compilation-buffer ()
    (let ((inhibit-read-only t))
      (ansi-color-apply-on-region (point-min) (point-max)))))

;; Browser
(req-package eww
  :loader :built-in
  :hook (eww-mode . buffer-face-mode))

(req-package face-remap
  :loader :built-in
  :diminish buffer-face-mode)

;; Code folding
(req-package hideshow
  :loader :built-in
  :diminish hs-minor-mode
  :hook (prog-mode . hs-minor-mode)
  :init
  (defun +hs-fold-overlay-ellipsis (ov)
    (when (eq 'code (overlay-get ov 'hs))
      (overlay-put
       ov 'display (propertize " … " 'face 'font-lock-comment-face))))

  (setq hs-hide-comments-when-hiding-all nil
        hs-set-up-overlay #'+hs-fold-overlay-ellipsis))

;; Line highlighting (builtin)
(req-package hl-line
  :loader :built-in
  :hook ((prog-mode text-mode conf-mode) . hl-line-mode)
  :init
  ;; Only highlight in selected window
  (setq hl-line-sticky-flag nil
        global-hl-line-sticky-flag nil))

;; Highlight matching delimiters
(req-package paren
  :loader :built-in
  :defer 2
  :init
  (setq show-paren-delay 0.1
        show-paren-highlight-openparen t
        show-paren-when-point-inside-paren t)
  :config
  (show-paren-mode 1))

;; Major mode for editing source code.
(req-package prog-mode
  :loader :built-in
  :hook (prog-mode
         . (lambda () (setq-local scroll-margin 4))))

;; Undo/redo window layout changes
(req-package winner
  :loader :built-in
  :hook (window-setup . winner-mode)
  :commands
  (winner-undo winner-redo)
  :init
  (defvar winner-dont-bind-my-keys t))

;;;
;; Packages

;; Hint mode for links
(req-package ace-link
  :commands
  (ace-link
   ace-link-help
   ace-link-org))

;; Fast window navigation
(req-package ace-window
  :commands
  (ace-window
   ace-swap-window ace-delete-window
   ace-select-window ace-delete-other-window)
  :init
  (setq aw-background t
        aw-keys '(?a ?s ?d ?f ?g ?h ?j ?k ?l)
        aw-scope 'frame))

;; Align visually wrapped lines
;; NOTE: This can cause performance issues with font-lock.
(req-package adaptive-wrap
  :commands adaptive-wrap-prefix-mode)

;; Jump to things
(req-package avy
  :commands
  (avy-goto-char-2
   avy-goto-line)
  :init
  (setq avy-all-windows nil
        avy-background t))

;; Bug references as buttons
(req-package bug-reference
  :loader :built-in
  :hook
  (prog-mode . bug-reference-prog-mode)
  ((text-mode magit-log-mode) . bug-reference-mode)
  :init
  (setq bug-reference-bug-regexp "\\(#\\|GH-\\)\\(?2:[0-9]+\\)"))

;; Use GitHub URL for bug reference
(req-package bug-reference-github
  :require bug-reference
  :after bug-reference
  :hook
  ((bug-reference-mode bug-reference-prog-mode) . bug-reference-github-set-url-format))

;; Centered window mode
(req-package centered-window-mode
  :diminish centered-window-mode
  :commands centered-window-mode
  :init
  (setq cwm-centered-window-width 120))

;; Highlight source code identifiers based on their name
(req-package color-identifiers-mode
  :diminish color-identifiers-mode
  :commands
  (color-identifiers-mode
   global-color-identifiers-mode
   color-identifiers:refresh)
  :defer 2
  :config
  (global-color-identifiers-mode 1))
(req-package rainbow-identifiers
  :diminish rainbow-identifiers-mode
  :commands rainbow-identifiers-mode
  :functions rainbow-identifiers-cie-l*a*b*-choose-face
  :init
  (setq rainbow-identifiers-choose-face-function 'rainbow-identifiers-cie-l*a*b*-choose-face
        rainbow-identifiers-cie-l*a*b*-saturation 65
        rainbow-identifiers-cie-l*a*b*-lightness 45))

;; Manual symbol highlight
(req-package symbol-overlay
  :diminish symbol-overlay-mode
  :commands
  (symbol-overlay-put
   symbol-overlay-switch-backward symbol-overlay-switch-forward)
  :hook (prog-mode . symbol-overlay-mode))

;; Dynamically change the default text scale
(req-package default-text-scale
  :commands
  (default-text-scale-increase default-text-scale-decrease))

(req-package eldoc-overlay-mode
  :diminish eldoc-overlay-mode
  :commands eldoc-overlay-mode)

;; Highlight TODO inside comments and strings
(req-package hl-todo
  :hook (prog-mode . hl-todo-mode))

;; Clickable links (builtin)
(req-package goto-addr
  :hook
  (text-mode . goto-address-mode)
  (prog-mode . goto-address-prog-mode))

;; For modes that don't adequately highlight numbers
(req-package highlight-numbers
  :commands highlight-numbers-mode)

;; Indentation guides
(req-package indent-guide
  :diminish indent-guide-mode
  :hook (prog-mode . indent-guide-mode)
  :init
  (setq indent-guide-delay 0.2
        indent-guide-char "\x2502"))

;; Flash the line around cursor on large movements
(req-package beacon
  :diminish beacon-mode
  :commands beacon-mode
  :config
  (defun +beacon-blink ()
    (when (bound-and-true-p beacon-mode)
      (beacon-blink)))

  (with-eval-after-load "evil"
    (advice-add #'evil-window-top    :after #'+beacon-blink)
    (advice-add #'evil-window-middle :after #'+beacon-blink)
    (advice-add #'evil-window-bottom :after #'+beacon-blink)))

;; Display page breaks as a horizontal line
(req-package page-break-lines
  :diminish page-break-lines-mode
  :commands
  (page-break-lines-mode
   global-page-break-lines-mode)
  :defer 2
  :config
  (global-page-break-lines-mode 1))

;; Visually separate delimiter pairs
(req-package rainbow-delimiters
  :hook
  ((lisp-mode emacs-lisp-mode) . rainbow-delimiters-mode)
  :init
  (setq rainbow-delimiters-max-face-count 3))

;; Make text readable
(req-package readable
  :loader :path
  :load-path my-site-lisp-dir
  :commands readable-mode)

;;;
;; Autoloads

;;;### autoload
(defun +color-identifiers-toggle ()
  "Toggle identifier colorization."
  (interactive)
  (if (or (bound-and-true-p color-identifiers-mode) (bound-and-true-p rainbow-identifiers-mode))
      (progn
        (color-identifiers-mode 0)
        (rainbow-identifiers-mode 0))
    (rainbow-identifiers-mode 1)))

;;;### autoload
(defun +color-identifiers-delayed-refresh ()
  "Refresh color identifiers with a delay."
  (run-with-idle-timer 0.2 nil #'color-identifiers:refresh))

(defun +rainbow-identifiers-delayed-refresh ()
  "Refresh rainbow identifiers with a delay."
  (run-with-idle-timer 0.2 nil #'refresh))

(provide 'base-ui)
;;; base-ui.el ends here
