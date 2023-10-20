;;; doom-modeline-workarounds.el --- Description -*- lexical-binding: t; -*-
;;; Re-added functions removed in https://github.com/seagle0128/doom-modeline/commit/b596440ee78b3e7d2debc3d73f4d938d968fb896

;;;###autoload
(defun doom-modeline-set-minimal-modeline ()
  "Set minimal mode-line."
  (doom-modeline-set-modeline 'minimal))

;;;###autoload
(defun doom-modeline-set-special-modeline ()
  "Set special mode-line."
  (doom-modeline-set-modeline 'special))

;;;###autoload
(defun doom-modeline-set-project-modeline ()
  "Set project mode-line."
  (doom-modeline-set-modeline 'project))

;;;###autoload
(defun doom-modeline-set-dashboard-modeline ()
  "Set dashboard mode-line."
  (doom-modeline-set-modeline 'dashboard))

;;;###autoload
(defun doom-modeline-set-vcs-modeline ()
  "Set vcs mode-line."
  (doom-modeline-set-modeline 'vcs))

;;;###autoload
(defun doom-modeline-set-info-modeline ()
  "Set Info mode-line."
  (doom-modeline-set-modeline 'info))

;;;###autoload
(defun doom-modeline-set-package-modeline ()
  "Set package mode-line."
  (doom-modeline-set-modeline 'package))

;;;###autoload
(defun doom-modeline-set-media-modeline ()
  "Set media mode-line."
  (doom-modeline-set-modeline 'media))

;;;###autoload
(defun doom-modeline-set-message-modeline ()
  "Set message mode-line."
  (doom-modeline-set-modeline 'message))

;;;###autoload
(defun doom-modeline-set-pdf-modeline ()
  "Set pdf mode-line."
  (doom-modeline-set-modeline 'pdf))

;;;###autoload
(defun doom-modeline-set-org-src-modeline ()
  "Set org-src mode-line."
  (doom-modeline-set-modeline 'org-src))
