;;; org-config.el  -*- ;;; no-byte-compile: t; lexical-binding: t; -*-

;;; Commentary:

;; My customizations for Org mode, including Org-roam and org-gtd.
;; Some of this is based on Emacs Bedrock.

;;; Code:
;; From Emacs Bedrock
(use-package org
  :hook ((org-mode . visual-line-mode)  ; wrap lines at word breaks
         (org-mode . flyspell-mode))    ; spell checking!

  :bind (:map global-map
              ("C-c l" . org-store-link))

  :config
  (require 'oc-csl)                     ; citation support
  (add-to-list 'org-export-backends 'md)

  ;; Make org-open-at-point follow file links in the same window
  (setf (cdr (assoc 'file org-link-frame-setup)) 'find-file)

  ;; Make exporting quotes better
  (setq org-export-with-smart-quotes t))

;;; (provide org-config.el)
;;; org-config.el ends here
