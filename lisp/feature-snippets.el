;;; feature-snippets.el --- Snippets -*- lexical-binding: t; -*-

;;; Commentary:
;; Explosive text.

;;; Code:

(eval-when-compile
  (require 'base-package))

;;;
;; Packages

(use-package yasnippet
  :demand t
  :diminish yas-minor-mode
  :mode
  ("\\.snippet$" . snippet-mode)
  ("\\.yasnippet$" . snippet-mode)
  :hook (after-init . yas-global-mode)
  :init
  (setq yas-snippet-dirs (list (concat user-emacs-directory "snippets"))
        yas-verbosity 0
        yas-indent-line 'auto
        yas-also-auto-indent-first-line t
        yas-snippet-revival t
        ;; Nested snippets
        yas-triggers-in-field t
        yas-wrap-around-region t)
  :config
  (with-eval-after-load 'evil
    (add-hook 'yas/before-expand-snippet-hook #'evil-insert-state)
    (add-hook 'evil-normal-state-entry-hook #'yas-abort-snippet)))

(use-package yasnippet-snippets
  :demand t)

(provide 'feature-snippets)
;;; feature-snippets.el ends here
