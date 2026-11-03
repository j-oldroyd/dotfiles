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
;; Remove error/help windows when no longer needed.  Adapted from
;; https://emacs.stackexchange.com/a/28695/45800.
(defun my/TeX-error-delete-window ()
  "Delete TeX error window when there are no errors to show."
  (let ((w (get-buffer-window))
        (b (get-buffer "*TeX Help*")))
    (when w
      (delete-window w))
    (when b
      (setq w (get-buffer-window b))
      (when w
        (delete-window w)))))

(defun my/TeX-error-install-delete-window-hook ()
  "Install `TeX-error-delete-window' in buffer-local `kill-buffer-hook'."
  (add-hook 'kill-buffer-hook #'my/TeX-error-delete-window nil t))

(add-hook 'TeX-error-overview-mode-hook
          #'my/TeX-error-install-delete-window-hook)

;; I want TeX windows to display on right even when using Olivetti.
(add-to-list 'display-buffer-alist
             '("\\*\\(?:TeX Help\\|TeX errors\\|[^*]+ output\\)\\*"
               (display-buffer-reuse-window display-buffer-in-direction)
               (direction . right)
               (window-width . 0.4)))

;;; CDLaTeX
;; Easy completions in LaTeX.
(use-package cdlatex
  :custom
  (cdlatex-use-dollar-to-ensure-math nil)

  :hook ((LaTeX-mode . cdlatex-mode)
         ;; karthink's code for integrating CDLaTeX with YASnippet.  Taken from
         ;; https://gist.github.com/karthink/7d89df35ee9b7ac0c93d0177b862dadb
         (cdlatex-tab . yas-expand)
         (cdlatex-tab . cdlatex-in-yas-field)
         (org-mode . turn-on-org-cdlatex))
  :diminish cdlatex-mode
  :diminish org-cdlatex-mode
  :config
  ;; BEGIN_KARTHINK
  (use-package yasnippet
    :bind (:map yas-keymap
                ("<tab>" . yas-next-field-or-cdlatex)
                ("TAB" . yas-next-field-or-cdlatex))
    :config
    (defun cdlatex-in-yas-field ()
      ;; Check if we're at the end of the Yas field
      (when-let* ((_ (overlayp yas--active-field-overlay))
                  (end (overlay-end yas--active-field-overlay)))
        (if (>= (point) end)
            ;; Call yas-next-field if cdlatex can't expand here
            (let ((s (thing-at-point 'sexp)))
              (unless (and s (assoc (substring-no-properties s)
                                    cdlatex-command-alist-comb))
                (yas-next-field-or-maybe-expand)
                t))
          ;; otherwise expand and jump to the correct location
          (let (cdlatex-tab-hook minp)
            (setq minp
                  (min (save-excursion (cdlatex-tab)
                                       (point))
                       (overlay-end yas--active-field-overlay)))
            (goto-char minp) t))))

    (defun yas-next-field-or-cdlatex nil
      "Jump to the next Yas field correctly with cdlatex active."
      (interactive)
      (if
          (or (bound-and-true-p cdlatex-mode)
              (bound-and-true-p org-cdlatex-mode))
          (cdlatex-tab)
        (yas-next-field-or-maybe-expand))))
  ;; END_KARTHINK
  )

;; Try to set up auto-expansion for certain snippets.
;; Taken from
;; https://www.reddit.com/r/emacs/comments/o5ewqc/is_automatic_snippet_expansion_with_yasnippet/
(defun my/yas-try-expanding-auto-snippets ()
  (when yas-minor-mode
    (let ((yas-buffer-local-condition ''(require-snippet-condition . auto)))
      (yas-expand))))
(add-hook 'post-command-hook #'my/yas-try-expanding-auto-snippets)

;; Enable LaTeX snippets in org-mode.  See
;; https://emacs.stackexchange.com/questions/38429/yasnippets-loading-two-major-modes-org-mode-and-latex
;; My snippets are currently in LaTeX-mode, so this might not work...
(defun my/org-latex-yas ()
  "Activate org and LaTeX yas expansion in org-mode buffers."
  (yas-minor-mode)
  (yas-activate-extra-mode 'latex-mode))

(add-hook 'org-mode-hook #'my/org-latex-yas)
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
