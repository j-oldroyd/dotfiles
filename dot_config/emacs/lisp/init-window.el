;;; init-window.el --- Configuration for windows in Emacs -*- no-byte-compile: t; lexical-binding: t; -*-

;;; Commentary:

;; My setup for window management in Emacs, based around ace-window.

;;; Code:

;;; ace-window
;; A package for comprehensive window management in Emacs.  The configuration
;; here is adapted from
;; https://www.polyomica.com/weekly-emacs-tip-20-emacs-window-management-quickly-moving-to-the-right-window-with-ace-window/
(use-package ace-window
  :ensure t
  :bind (("M-o" . ace-window)
         ("M-O" . ace-delete-window))
  :custom
  ;; Don't use numbers to label the windows, but the keys on home row.
  (aw-keys '(?a ?s ?d ?f ?g ?h ?j ?k ?l))
  :config
  ;; Set the colour and size of the font used to display the selection
  ;; characters
  (set-face-attribute 'aw-leading-char-face nil
                      :foreground "deep sky blue"
                      :weight 'bold
                      :height 3.0))

(provide 'init-window)
;;; init-window.el ends here
