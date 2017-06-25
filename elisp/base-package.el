;;; base-package.el --- Package configuration

;;; Commentary:
;; Sharing is caring.

;;; Code:
(require 'base-vars)

(require 'package)
(require 'tls)

(defvar my-packages-init-p nil
  "Non-nil if the package system has been initialized.
This will be nil if you have byte-compiled your configuration.")

;;;
;; Settings
(setq-default
 load-prefer-newer noninteractive
 ;; Workaround package.el bug in Emacs 25
 package--init-file-ensured t
 package-enable-at-startup nil
 package-user-dir (expand-file-name "elpa" my-packages-dir)
 package-archives
 '(("gnu"   . "https://elpa.gnu.org/packages/")
   ("melpa" . "https://melpa.org/packages/"))

 gnutls-verify-error t
 tls-checktrust gnutls-verify-error

 use-package-always-defer t
 use-package-always-ensure t
 use-package-debug nil
 use-package-expand-minimally (eval-when-compile (not my-debug-mode))
 use-package-minimum-reported-time (if my-debug-mode 0 0.1)
 use-package-verbose my-debug-mode

 byte-compile-dynamic nil
 byte-compile-verbose my-debug-mode
 byte-compile-warnings '(not free-vars unresolved noruntime lexical make-local))

(defun my|packages-initialize (&optional force-p)
  "Initialize installed packages and ensure they are installed.
When FORCE-P is provided it will run no matter the preconditions.
When base.el is compiled, this function will be avoided to speed up startup."
  (when (or (not my-packages-init-p) force-p)
    (unless noninteractive
      (message "Emacs initialized"))

    ;; Ensure folders exist
    (dolist (dir (list my-cache-dir my-data-dir my-packages-dir))
      (unless (file-directory-p dir)
        (make-directory dir t)))

    (package-initialize)
    (unless package-archive-contents
      (package-refresh-contents))

    (unless (package-installed-p 'paradox)
      (package-install 'paradox))
    (paradox-require 'use-package)

    (setq my-packages-init-p t)))

(autoload 'paradox-require "paradox" nil nil 'macro)
(autoload 'use-package "use-package" nil nil 'macro)

(provide 'base-package)
;;; base-package.el ends here