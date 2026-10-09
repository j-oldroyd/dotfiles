;;; post-early-init.el --- Late early initializations -*- ;;; no-byte-compile: t; lexical-binding: t; -*-

;;; Commentary:

;;; Code:

;; Set UTF-8 on WSL machines
;; https://emacs.stackexchange.com/a/75782/45800
(cond ((or (eq system-type 'windows-nt) (eq system-type 'gnu/linux))
       ;; Windows-specific code goes here.
       (prefer-coding-system 'utf-8-unix)
       (setq coding-system-for-read 'utf-8-unix)
       (setq coding-system-for-write 'utf-8-unix)))

;;; (provide post-early-init.el)
;;; post-early-init.el ends here
