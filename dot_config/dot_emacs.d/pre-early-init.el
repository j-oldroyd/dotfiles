;;; pre-early-init.el --- Very early initializations -*- ;;; no-byte-compile: t; lexical-binding: t; -*-

;;; Commentary:

;;; Code:

;; Basic UI
(setq minimal-emacs-ui-features '(context-menu tool-bar menu-bar dialogs tooltips))


;;; Reducing clutter in ~/.emacs.d by redirecting files to ~/.emacs.d/var/
(setq user-emacs-directory
      (expand-file-name "var/" minimal-emacs-user-directory))
(setq package-user-dir (expand-file-name "elpa" user-emacs-directory))

;;; (provide pre-early-init.el)
;;; pre-early-init.el ends here
