;;; base-projects.el --- Project configuration -*- lexical-binding: t; -*-

;;; Commentary:
;; Project management.

;;; Code:

(eval-when-compile
  (require 'base-vars)
  (require 'base-package))

;;;
;; Packages

(req-package projectile
  :diminish projectile-mode
  :demand t
  :init
  (setq projectile-cache-file (concat my-cache-dir "projectile.cache")
        projectile-enable-caching nil
        projectile-file-exists-remote-cache-expire nil
        projectile-globally-ignored-file-suffixes
        '(".elc" ".pyc" ".o" ".hi" ".class" ".cache")
        projectile-globally-ignored-files
        '("TAGS" "GPATH" "GRTAGS" "GTAGS")
        projectile-indexing-method 'alien
        projectile-ignored-projects (list my-data-dir)
        projectile-known-projects-file (concat my-cache-dir "projectile.projects"))
  :config
  (defun +projectile-cache-current-file (orig-fun &rest args)
    "Don't cache ignored files."
    (unless (cl-some (lambda (path)
                       (string-prefix-p buffer-file-name
                                        (expand-file-name path)))
                     (projectile-ignored-directories))
      (apply orig-fun args)))
  (advice-add #'projectile-cache-current-file :around #'+projectile-cache-current-file)

  (setq projectile-globally-ignored-directories
        (append '("_build" "elm-stuff" "tests/elm-stuff")
                projectile-globally-ignored-directories))

  (setq projectile-project-root-files
        (append '("package.json" "Package.swift" "README.md")
                projectile-project-root-files))
  (setq projectile-other-file-alist
        (append '(("less" "css")
                  ("styl" "css")
                  ("sass" "css")
                  ("scss" "css")
                  ("css" "scss" "sass" "less" "styl")
                  ("jade" "html")
                  ("pug" "html")
                  ("html" "jade" "pug" "jsx" "tsx"))
                projectile-other-file-alist))

  (projectile-mode 1))

;;;
;; Buffer filtering

(defun +is-useful-buffer (buffer)
  "Determine if BUFFER is useful."
  (not (string-match
        "^ ?\\*.*\\*\\(<[0-9]+>\\)?$"
        (buffer-name buffer))))

(defun +is-current-persp-buffer (buffer)
  "Determine if BUFFER belongs to current persp."
  (if (fboundp 'persp-buffer-list)
      (memq buffer (persp-buffer-list))
    t))

(defun +is-visible-buffer (buffer)
  "Determine if BUFFER should be visible."
  (and (+is-useful-buffer buffer) (+is-current-persp-buffer buffer)))

;; Filter out buffers that is not deemed visible.
(push '(buffer-predicate . +is-visible-buffer) default-frame-alist)

(provide 'base-projects)
;;; base-projects.el ends here