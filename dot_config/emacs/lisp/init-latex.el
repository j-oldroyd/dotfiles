;;; init-latex.el --- Configuration for LaTeX-mode  -*- no-byte-compile: t; lexical-binding: t; -*-

;;; Commentary:

;; My customizations for LaTeX in Emacs.  This is primarily handled by AUCTeX
;; and CDLaTeX, though other customizations.

;;; Code:

;;; AUCTeX
(use-package auctex
  :hook ((LaTeX-mode . turn-on-reftex)
         (LaTeX-mode . rainbow-delimiters-mode)
         (LaTeX-mode . prettify-symbols-mode))
  :custom
  (reftex-plug-into-AUCTeX t)
  (TeX-error-overview-open-after-TeX-run t)
  (TeX-electric-math (cons "\\(" ""))
  (TeX-open-quote "``")
  (TeX-close-quote "''")
  (TeX-auto-save t)
  (TeX-parse-self t)
  (TeX-master nil)
  (adaptive-wrap-extra-indent 2)
  ;; PDF and SyncTeX settings
  (TeX-view-program-selection '((output-pdf "PDF Tools")))
  (TeX-source-correlate-mode t)
  (TeX-source-correlate-start-server t)
  (TeX-source-correlate-method 'synctex)
  :config
  ;; Update PDF buffers after successful TeX runs.
  ;; `use-package' appends "-hook" to every name given to :hook, so hooks whose
  ;; names end in "-functions" (such as
  ;; `TeX-after-compilation-finished-functions') must be added with `add-hook'.

  (add-hook 'TeX-after-compilation-finished-functions
            #'TeX-revert-document-buffer))

;; AUCTeX's live preview requires ghostscript, so we tell AUCTeX where to
;; find it on macOS.  Live preview on Windows is very troublesome, so we
;; don't worry about it.
(when (eq system-type 'darwin)
  (setq preview-gs-command "/opt/homebrew/bin/gs"))

;;; Buffer settings
;; Remove error/help windows when no longer needed.
(defun my/TeX-error-install-delete-window-hook ()
  "Install `TeX-error-delete-window' in buffer-local `kill-buffer-hook'."
  (add-hook 'kill-buffer-hook #'TeX-error-delete-window nil t))

(add-hook 'TeX-error-overview-mode-hook
          #'my/TeX-error-install-delete-window-hook)

;; I want TeX windows to display on right even when using Olivetti.
(add-to-list 'display-buffer-alist
             '("\\*\\(?:TeX Help\\|TeX errors\\|[^*]+ output\\)\\*"
               (display-buffer-reuse-window display-buffer-in-direction)
               (direction . right)
               (window-width . 0.4)))

;;; CDLaTeX
;; Easy completions in LaTeX.  TODO: The YASnippet integration (`cdlatex-tab'
;; hooks and `yas-next-field-or-cdlatex') lives in post-init.el; consider
;; merging that block into this one so cdlatex is configured in a single place.
(use-package cdlatex
  :hook (LaTeX-mode . cdlatex-mode)
  :custom
  (cdlatex-use-dollar-to-ensure-math nil))

;;; Adjacent tools
;; Allow for easy use of latexdiff.
(use-package latexdiff)

;;; Sage
;; We need to modify sage-shell to accept filepaths with spaces in their
;; names.  This appears to require modifying
;; `sage-shell-sagetex:tex-master-maybe'.  (`advice-add' accepts functions that
;; are not defined yet, so this works even before sage-shell is loaded.)
(defun my/sage-shell-sagetex-tex-master-maybe (_orig-fn f &optional nondir)
  "Around advice for `sage-shell-sagetex:tex-master-maybe'.
_ORIG-FN is the original function; F is the file and NONDIR is as in the
original."
  (let* ((b (get-file-buffer f))
         (tm (when (and (bufferp b)
                        (boundp 'TeX-master))
               (buffer-local-value 'TeX-master b))))
    (let ((ms (cond ((and tm (stringp tm))
                     (shell-quote-argument
                      (expand-file-name tm (file-name-directory f))))
                    (t f))))
      (if nondir (file-name-nondirectory ms)
        ms))))

(advice-add 'sage-shell-sagetex:tex-master-maybe
            :around #'my/sage-shell-sagetex-tex-master-maybe)

;; FIXME: When `TeX-master' is a string, the around advice above already
;; quotes the result, and this :filter-return advice quotes it again.  Test
;; with a path containing spaces; one of the two is probably redundant.
;; (advice-add 'sage-shell-sagetex:tex-master-maybe
;;             :filter-return #'shell-quote-argument)

(provide 'init-latex)
;;; init-latex.el ends here
