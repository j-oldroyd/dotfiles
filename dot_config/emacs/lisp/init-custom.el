;;; init-custom.el --- Configuration of general, custom variables -*- no-byte-compile: t; lexical-binding: t; -*-

;;; Commentary:

;; This file keeps track of custom variables I want to set Emacs-wide.  These
;; include built-in variables (many of which can be managed with the emacs
;; "package") and personal variables that are created here and have values
;; stored in a custom.el file that is not tracked.


;;; Emacs
(use-package emacs
  :init
  (setq user-full-name "Jesse Ernest Oldroyd")
  :config
  ;; The settings below are suggested by Emacs Redux (the creator of
  ;; Prelude).  See
  ;; https://emacsredux.com/blog/2026/04/07/stealing-from-the-best-emacs-configs/
  (setq redisplay-skip-fontification-on-input t)
  (setq save-interprogram-paste-before-kill t)
  (setq-default cursor-in-non-selected-windows nil)
  (setq highlight-nonselected-windows nil)
  (setq kill-do-not-save-duplicates t))

;;; User variables
;; Cloud storage
(defcustom user-cloud-storage "~/Google Drive"
  "Cloud storage directory."
  :type 'directory)

(provide 'init-custom)
;;; init-custom.el ends here
