;;; post-early-init.el --- Late early initializations -*- ;;; no-byte-compile: t; lexical-binding: t; -*-

;;; Commentary:

;;; Code:

;;; Encoding
;; Set UTF-8 on WSL machines
;; https://emacs.stackexchange.com/a/75782/45800
(cond ((or (eq system-type 'windows-nt) (eq system-type 'gnu/linux))
       ;; Windows-specific code goes here.
       (prefer-coding-system 'utf-8-unix)
       (setq coding-system-for-read 'utf-8-unix)
       (setq coding-system-for-write 'utf-8-unix)))


;;: Modeline
;; Taken from
;; https://github.com/MatthewZMD/.emacs.d?tab=readme-ov-file#doom-modeline
(use-package doom-modeline
  :ensure t
  :custom
  ;; Don't compact font caches during GC. Windows Laggy Issue
  (inhibit-compacting-font-caches t)
  (doom-modeline-minor-modes t)
  (doom-modeline-icon t)
  (doom-modeline-major-mode-color-icon t)
  (doom-modeline-height 15)
  :config
  (doom-modeline-mode))

;; Diminish will help keep the modeline clean via :diminish keyword
(use-package diminish
  :ensure t)

;; (provide post-early-init.el)
;;; post-early-init.el ends here
