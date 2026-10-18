;;; init-research.el --- Configuration for research workflow -*- no-byte-compile: t; lexical-binding: t; -*-

;;; Commentary:

;; Customizations that support a research workflow in Emacs.  This is centered
;; around Org roam for note-taking and citar for bibliography management.

;;; Code:

;;; Org roam
(use-package org-roam
  :ensure t
  :bind (("C-c n l" . org-roam-buffer-toggle)
         ("C-c n f" . org-roam-node-find)
         ("C-c n g" . org-roam-ui-open)
         ("C-c n i" . org-roam-node-insert)
         ("C-c n c" . org-roam-capture)
         ;; Dailies for journaling
         ("C-c n j" . org-roam-dailies-capture-date))
  :config
  ;; If you're using a vertical completion framework, you might want a
  ;; more informative completion interface
  (setq org-roam-node-display-template
        (concat "${title:*} " (propertize "${tags:10}" 'face 'org-tag)))
  (org-roam-db-autosync-mode)
  ;; If using org-roam-protocol
  (require 'org-roam-protocol)

  :custom
  (org-roam-directory (expand-file-name "org/roam" user-cloud-storage))
  ;; Dailies setup
  (org-roam-dailies-directory "daily/")
  (org-roam-dailies-capture-templates
   '(("d" "default" entry "* %?"
      :target (file+head "%<%Y-%m-%d>.org" "#+title: %<%Y-%m-%d>\n")))))

;; Notes template based on suggested citar config and Jethro Kuan's setup.
(setq org-roam-capture-templates
      '(("m" "main" plain
         "%?"
         :if-new (file+head "main/${slug}.org"
                            "#+title: ${title}\n")
         ;; :target
         ;; (file+head
         ;;  "%<%Y%m%d%H%M%S>-${slug}.org"
         ;;  "#+title: ${note-title}\n")
         :unnarrowed t)
        ("r" "reference note" plain
         "%?"
         :target
         (file+head
          "%(expand-file-name (or citar-org-roam-subdir \"\") org-roam-directory)/${citar-citekey}.org"
          "#+title: ${citar-citekey}. ${note-title}.\n#+created: %U\n#+last_modified: %U\n\n* Main idea(s) and keywords\n* Key definition(s)\n* Key results\n* Questions and follow-ups")
         :unnarrowed t)
        ("a" "article" plain "%?"
         :if-new
         (file+head "articles/${title}.org" "#+title: ${title}\n#+filetags: :article:\n")
         :immediate-finish t
         :unnarrowed t)))

;; org-roam-ui defaults taken from GitHub
(use-package org-roam-ui
  :ensure t
  :after org-roam
  :config
  (setq org-roam-ui-sync-theme t
        org-roam-ui-follow t
        org-roam-ui-update-on-save t
        org-roam-ui-open-on-start t))

;;; org-noter
;; This package allows you to create a notes file to "attach" to another
;; document, such as a PDF.
(use-package org-noter
  :ensure t)

;;; Bibliography management
(use-package bib-mode
  ;; Elpaca seems to yell if I don't set :ensure nil.
  :ensure nil
  :custom
  (bib-file '(expand-file-name "research/My Library.bib" user-cloud-storage)))

(use-package org
  :custom
  (org-cite-global-bibliography bib-file)
  (org-cite-insert-processor 'citar)
  (org-cite-follow-processor 'citar)
  (org-cite-activate-processor 'citar))

(use-package citar
  ;; I don't want to load this just yet.  Instead, I'll set
  ;; OS-specific variables first.
  :defer t
  :if (eq system-type 'darwin)
  :custom
  (citar-library-paths '("~/Google Drive/My Drive/research"))
  (citar-notes-paths '("~/Google Drive/My Drive/research")))

(use-package citar
  ;; I don't want to load this just yet.  Instead, I'll set
  ;; OS-specific variables first.
  :defer t
  :if (eq system-type 'gnu/linux)
  :custom
  (citar-library-paths '("~/GoogleDrive/research"))
  (citar-notes-paths '("~/GoogleDrive/research")))

(use-package citar
  :ensure t
  :diminish
  :custom
  (citar-bibliography org-cite-global-bibliography)
  (citar-org-roam-subdir "references")
  (bibtex-dialect "biblatex")
  ;; This assumes that you use Zotero with Better BibTeX.  If not,
  ;; just use the default.
  (citar-open-entry-function 'citar-open-entry-in-zotero)
  :hook
  (LaTeX-mode . citar-capf-setup)
  (org-mode . citar-capf-setup))

(use-package citar-org-roam
  :ensure t
  :diminish
  :custom
  (citar-org-roam-capture-template-key "r")
  :after (org-roam citar)
  :config (citar-org-roam-mode))

(use-package citar-embark
  :ensure t
  :diminish
  :after (citar embark)
  :no-require
  :config (citar-embark-mode))

;; The code below allows me to use Citar and org-cite with Zotero styles.
;; Taken from: https://www.reddit.com/r/orgmode/comments/umqu4o/comment/i83m6xk/?utm_source=share&utm_medium=web3x&utm_name=web3xcss&utm_term=1&utm_content=share_button
(setopt org-cite-export-processors '((t csl)))
(setopt org-cite-csl-styles-dir "~/Zotero/styles")

(provide 'init-research)
;;; init-research.el ends here
