;;; base-lib.el --- Library functions -*- lexical-binding: t; -*-

;;; Commentary:
;; Custom functions, macros and helpers.

;;; Code:

(eval-when-compile
  (require 'base-vars)
  (require 'base-package))

(defvar-local documentation-function nil
  "Function to use for documentation look-ups.")

;;;
;; Packages

;; Set multiple hooks
(req-package add-hooks :force t
  :commands (add-hooks add-hooks-pair))

;; Enable Emacs minor modes by buffer name and contents
(req-package auto-minor-mode :force t :demand t)

;; Hide lines based on regexp
(req-package hide-lines :force t
  :commands
  (hide-lines hide-lines-matching hide-lines-not-matching hide-lines-show-all))

;; Show tooltip at point
(req-package pos-tip :force t)

;; Inline popups
(req-package quick-peek :force t
  :commands (quick-peek-show quick-peek-hide))

;; Diminish lines
(req-package diminish :force t
  :commands diminish)

(req-package spinner :force t
  :commands (spinner-start spinner-create spinner-print))

(req-package f    :force t) ; files and paths
(req-package s    :force t) ; strings
(req-package dash :force t) ; lists
(req-package ov   :force t) ; overlays

(req-package blacklist-minor-modes :force t
  :load-path my-site-lisp-dir
  :commands blacklist-minor-modes)

;;;
;; Setup

(defmacro set-evil-state (modes state)
  "Set MODES initial STATE using `evil-set-initial-state'."
  `(with-eval-after-load 'evil
     (dolist (mode (if (listp ,modes) ,modes (list ,modes)))
       (evil-set-initial-state mode ,state))))

(defmacro set-on-evil-state (modes state &rest forms)
  "Set MODES state entry hooks for STATE using FORMS."
  `(let* ((modes (if (listp ,modes) ,modes (list ,modes)))
          (modes-name (mapconcat #'symbol-name modes "-"))
          (mode-hook-fn-name (intern (format "add-evil-%s-state-entry-hook--%s" ,state modes-name)))
          (state-hook (intern (format "evil-%s-state-entry-hook" ,state)))
          (state-hook-fn-name (intern (format "on-%s-state-entry--%s" ,state modes-name))))
     (defalias state-hook-fn-name (lambda () ,@forms))
     (defalias mode-hook-fn-name `(lambda () (add-hook ',state-hook #',state-hook-fn-name nil t)))
     (add-hooks-pair modes mode-hook-fn-name)))

(defmacro set-aggressive-indent (modes &rest plist)
  "Set MODES `agressive-indent' configuration through PLIST.
The list accepts the following properties:

:disabled BOOLEAN
  Disable auto-indent."
  (let ((disabled (plist-get plist :disabled)))
    `(with-eval-after-load 'aggressive-indent
       (dolist (mode (if (listp ,modes) ,modes (list ,modes)))
         (when ,disabled
           (cl-pushnew mode aggressive-indent-excluded-modes :test #'equal))))))

(defmacro set-prettify-symbols (modes symbols)
  "Set MODES prettified symbols to SYMBOLS."
  `(let* ((modes (if (listp ,modes) ,modes (list ,modes)))
          (fn-name (intern (format "set-prettify-symbols--%s" (mapconcat #'symbol-name modes "-")))))
     (defalias fn-name
       (lambda () (dolist (symbol ,symbols)
               (push symbol prettify-symbols-alist))))
     (add-hooks-pair modes fn-name)))

(defmacro set-doc-fn (modes function)
  "Set MODES documentation FUNCTION using `documentation-function'."
  `(let* ((modes (if (listp ,modes) ,modes (list ,modes)))
          (fn-name (intern (format "set-doc-fn--%s" (mapconcat #'symbol-name modes "-")))))
     (defalias fn-name
       (lambda () (setq documentation-function ,function)))
     (add-hooks-pair modes fn-name)))

(defun documentation-at-point ()
  "Get documentation at point using `documentation-function'."
  (interactive)
  (if (commandp documentation-function)
      (call-interactively documentation-function)
    (call-interactively 'source-peek)))

(defmacro set-company-backends (mode &rest backends)
  "For MODE add BACKENDS to buffer-local version of `company-backends'."
  `(with-eval-after-load 'company
     (add-hooks-pair
      ,mode
      (lambda ()
        (make-variable-buffer-local 'company-backends)
        (dolist (backend (list ,@(reverse backends)))
          (cl-pushnew backend company-backends :test #'equal))))))

(defun set-popup-buffer (&rest buffers)
  "Display BUFFERS as popup."
  (dolist (buffer buffers)
    (cl-pushnew `(,buffer
                  (display-buffer-reuse-window
                   display-buffer-in-side-window)
                  (reusable-frames . visible)
                  (side            . bottom)
                  (window-height   . 0.4))
                display-buffer-alist :test #'equal)))

(defun set-repl-command (mode command)
  "Define a REPL for MODE by running COMMAND."
  (cl-pushnew (cons mode command) eval-repl-alist :test #'equal))

(defun set-eval-command (mode command)
  "Define eval function for MODE by running COMMAND."
  (cl-pushnew (cons mode command) eval-runner-alist :test #'equal))

(defmacro add-graphic-hook (&rest forms)
  "Add FORMS as a graphical hook."
  `(if (daemonp)
       (add-hook 'after-make-frame-functions
                 (lambda (frame)
                   (with-selected-frame frame
                     (progn ,@forms))))
     (when (display-graphic-p)
       (add-hook 'after-init-hook
                 (lambda () (progn ,@forms))))))

(defmacro add-terminal-hook (&rest forms)
  "Add FORMS as a graphical hook."
  `(if (daemonp)
       (add-hook 'after-make-frame-functions
                 (lambda (frame)
                   (unless (display-graphic-p frame)
                     (with-selected-frame frame
                       (progn ,@forms)))))
     (unless (display-graphic-p)
       (add-hook 'after-init-hook
                 (lambda () (progn ,@forms))))))

(defmacro quiet! (&rest forms)
  "Run FORMS without making any noise."
  `(if my-debug-mode
       (progn ,@forms)
     (fset '+old-write-region-fn (symbol-function 'write-region))
     (cl-letf ((standard-output (lambda (&rest _)))
               ((symbol-function 'load-file) (lambda (file) (load file nil t)))
               ((symbol-function 'message) (lambda (&rest _)))
               ((symbol-function 'write-region)
                (lambda (start end filename &optional append visit lockname mustbenew)
                  (unless visit (setq visit 'no-message))
                  (when (fboundp '+old-write-region-fn)
                    (+old-write-region-fn
                     start end filename append visit lockname mustbenew))))
               (inhibit-message t)
               (save-silently t))
       ,@forms)))

(defun run-prog-mode-hooks ()
  "Run hooks all `prog-mode' hooks."
  (run-hooks 'prog-mode-hook))

;;;
;; Buffers

;;;### autoload
(defun kill-other-buffers ()
  "Kill all other buffers."
  (interactive)
  (mapc 'kill-buffer
        (delq (current-buffer)
              (cl-remove-if-not 'buffer-file-name (buffer-list)))))

;;;### autoload
(defun switch-to-minibuffer ()
  "Switch to minibuffer window."
  (interactive)
  (if (active-minibuffer-window)
      (select-window (active-minibuffer-window))
    (error "Minibuffer is not active")))

;;;### autoload
(defun toggle-scratch-buffer ()
  "Toggle scratch buffer."
  (interactive)
  (open-and-switch-to-buffer #'nil "*scratch*"))

;;;### autoload
(defun open-and-switch-to-buffer (command buffer &optional do-switch)
  "Open a `COMMAND', and switch to that `BUFFER' when `DO-SWITCH'."
  (interactive)
  (if (get-buffer buffer)
      (switch-to-buffer-other-window buffer)
    (progn
      (call-interactively command)
      (when do-switch
        (switch-to-buffer-other-window buffer)))))

;;;### autoload
(defun get-buffer-display-time (buffer)
  "Get the display time for BUFFER."
  (with-current-buffer buffer
    (float-time buffer-display-time)))

;;;
;; Editing

;;;### autoload
(defun retab-buffer ()
  "Convert tabs to spaces, or spaces to tabs based on `indent-tabs-mode' and `tab-width'."
  (interactive)
  (save-excursion
    (if indent-tabs-mode
        (tabify (point-min) (point-max))
      (untabify (point-min) (point-max)))))

;;;
;; UI

;;;### autoload
(defun text-scale-reset ()
  "Reset text scale by setting it to 0."
  (interactive)
  (text-scale-set 0))

;;;### autoload
(defun line-cursor ()
  "Use line cursor instead of regular cursor."
  (interactive)
  (hl-line-mode 1)
  (setq-local cursor-type nil))

(defun show-cursor ()
  "Show cursor."
  (interactive)
  (internal-show-cursor (get-buffer-window) t))

;;;### autoload
(defun hide-fringes ()
  "Hide fringes for buffer."
  (interactive)
  (set-window-fringes (get-buffer-window) 0 0 nil))

;;;### autoload
(defun hide-mode-line ()
  "Hide mode line for buffer."
  (interactive)
  (setq mode-line-format nil))

;;;### autoload
(defun default-text-scale-reset ()
  "Reset the height of the default face to `my-default-font-height'."
  (interactive)
  (set-face-attribute 'default nil :height my-default-font-height))

;;;### autoload
(defun refresh ()
  "Refresh buffer."
  (interactive)
  (font-lock-flush))

(provide 'base-lib)
;;; base-lib.el ends here
