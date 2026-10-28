;;; init-docs.el --- Configuration for documents in Emacs  -*- no-byte-compile: t; lexical-binding: t; -*-

;;; Commentary:
;; Settings for working with documents (such as PDFs and EPUBs) in Emacs.

;;; PDF
;; I use PDF Tools to handle PDFs in Emacs.  This includes SyncTeX with LaTeX
;; files.  Taken from
;; https://www.reddit.com/r/emacs/comments/gm1c2p/pdftools_installation/
(use-package pdf-tools
  :ensure t
  :bind
  (:map pdf-view-mode-map
        ("M-g g" . pdf-view-goto-page))
  :config
  (pdf-tools-install)
  (setq-default pdf-view-display-size 'fit-page)
  :hook
  ((pdf-view-mode . pdf-view-roll-minor-mode)
   ;; hl-line-mode clashes with pdf-view-roll-minor-mode
   (pdf-view-mode . (lambda ()
                      (setq-local global-hl-line-mode nil)))))

;; Apparently line numbers break horizontal scrolling in PDF Tools.
;; Code below taken from
;; emacs.stackexchange.com/questions/74317/how-can-i-get-horizontal-scrolling-in-pdfview-to-work
(defun bugfix-display-line-numbers--turn-on (fun &rest args)
  "Avoid `display-line-numbers-mode' in `image-mode' and related.
Around advice for FUN with ARGS."
  (unless (derived-mode-p 'image-mode 'docview-mode 'pdf-view-mode)
    (apply fun args)))

(advice-add 'display-line-numbers--turn-on :around #'bugfix-display-line-numbers--turn-on)

(use-package pdf-meta-edit
  :ensure t)

;;; EPUB
(use-package nov
  :ensure t
  :hook
  ((nov-mode . visual-line-mode)
   ;; (nov-mode . visual-fill-column-mode)
   )
  :init
  (add-to-list 'auto-mode-alist '("\\.epub\\'" . nov-mode)))

(provide 'init-docs)
;;; init-docs.el ends here
