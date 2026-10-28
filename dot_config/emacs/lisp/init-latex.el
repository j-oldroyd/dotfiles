;;; init-latex.el --- Configuration for LaTeX-mode  -*- no-byte-compile: t; lexical-binding: t; -*-

;;; Commentary:

;; My customizations for LaTeX in Emacs.  This is primarily handled by AUCTeX
;; and CDLaTeX, though other customizations.
(use-package auctex
  :ensure t
  :defer t
  :hook ((LaTeX-mode . turn-on-reftex)
         (LaTeX-mode . rainbow-delimiters-mode)
         (LaTeX-mode . prettify-symbols-mode))
  :custom
  (reftex-plug-into-AUCTeX t)
  (TeX-error-overview-open-after-TeX-run t)
  (TeX-electric-math (cons "\\(" ""))
  (cdlatex-use-dollar-to-ensure-math nil)
  (TeX-open-quote "``")
  (TeX-close-quote "''")
  (TeX-auto-save t)
  (TeX-parse-self t)
  (TeX-master nil)
  (adaptive-wrap-extra-indent 2))

;; AUCTeX's live preview requires ghostscript, so we tell AUCTeX where to
;; find it on macOS. Live preview on Windows is very troublesome, so we
;; don't worry about it.
(when (eq system-type 'darwin)
  (setq preview-gs-command "/opt/homebrew/bin/gs"))

;;; CDLaTeX
;; Easy completions in LaTeX
(use-package cdlatex
  :ensure t
  :defer t
  :hook
  ((LaTeX-mode . cdlatex-mode)))

;;; PDF and SyncTeX settings
(use-package auctex
  :custom
  (TeX-view-program-selection '((output-pdf "PDF Tools")))
  (TeX-source-correlate-mode t)
  (TeX-source-correlate-start-server t)
  (TeX-source-correlate-method (quote synctex))
  ;; Update PDF buffers after successful TeX runs
  :hook
  (TeX-after-compilation-finished-functions . TeX-revert-document-buffer))

;;; Buffer settings
;; I want TeX windows to display on right even when using Olivetti.
(add-to-list 'display-buffer-alist
             '("\\*\\(?:TeX Help\\|TeX errors\\|[^*]+ output\\)\\*"
               (display-buffer-reuse-window display-buffer-in-direction)
               (direction . right)
               (window-width . 0.4)))

;;; Adjacent tools
;; Allow for easy use of latexdiff.
(use-package latexdiff
  :ensure t)

;; We need to modify sage-shell to accept filepaths with spaces in their
;; names. This appears to require modifying
;; sage-shell-sagetex:tex-master-maybe.
(advice-add 'sage-shell-sagetex:tex-master-maybe
            :around #'my-sage-shell-sagetex:tex-master-maybe)

;; Sage functions in Emacs
(defun my-sage-shell-sagetex:tex-master-maybe (sage-shell-sagetex:tex-master-maybe f &optional nondir)
  (let* ((b (get-file-buffer f))
         (tm (when (and (bufferp b)
                        (boundp 'TeX-master))
               (buffer-local-value 'TeX-master b))))
    (let ((ms (cond ((and tm (stringp tm))
                     (shell-quote-argument (expand-file-name tm (file-name-directory f))))
                    (t f))))
      (if nondir (file-name-nondirectory ms)
        ms))))

(advice-add 'sage-shell-sagetex:tex-master-maybe
            :filter-return #'shell-quote-argument)

(provide 'init-latex)
;;; init-latex.el ends here
