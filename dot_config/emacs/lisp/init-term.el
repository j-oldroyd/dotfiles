;;; init-term.el --- Configuration for terminals in Emacs -*- no-byte-compile: t; lexical-binding: t; -*-

;;; Commentary:

;; This configuration makes use of ghostel over vterm and eshell.

;;; Code:

;;; ghostel
;; This provides a terminal emulator based on ghostty which allows for
;; modern conveniences such as images.  The configuration below is
;; taken from the suggested setup on ghostel's GitHub page.
(use-package ghostel
  :bind (("C-x m" . ghostel)
         :map ghostel-semi-char-mode-map
         ("C-s"  . consult-line)
         ("C-k"  . my/ghostel-send-C-k-and-kill)
         ;; I'm used to go up/down the shell history with M-n/p from eshell
         ;; Simulate this behavior in ghostel by sending C-p and C-n
         ("M-p" . (lambda () (interactive) (ghostel-send-key "p" "ctrl")))
         ("M-n" . (lambda () (interactive) (ghostel-send-key "n" "ctrl")))
         :map project-prefix-map
         ("m" . ghostel-project)
         ("M" . ghostel-project-list-buffers))

  :config
  (defun my/ghostel-send-C-k-and-kill ()
    "Send `C-k' to ghostel.
Like normal Emacs `C-k'.  Kill to end of line and put content in kill-ring."
    (interactive)
    (kill-ring-save (point) (line-end-position))
    (ghostel-send-key "k" "ctrl"))

  (add-to-list 'project-switch-commands '(ghostel-project "Ghostel") t)
  (add-to-list 'project-switch-commands '(ghostel-project-list-buffers "Ghostel buffers") t)
  (add-to-list 'ghostel-eval-cmds '("magit-status-setup-buffer" magit-status-setup-buffer))

  :if (eq system-type 'darwin)
  :ensure t)

(use-package consult-ghostel
  :hook (after-init . consult-ghostel-mode)
  :bind (("C-x m" . consult-ghostel)
         :map project-prefix-map
         ("m" . consult-ghostel-project)
         :map ghostel-semi-char-mode-map
         ("C-c h" . consult-ghostel-history)))

(provide init-term)
;;; init-term.el ends here
