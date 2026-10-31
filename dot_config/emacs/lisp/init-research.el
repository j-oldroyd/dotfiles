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
         ("C-c n j" . org-roam-dailies-capture-date)
         ;; Open note for bib file
         ("C-c n b" . citar-open)
         ;; Helper functions
         ("C-c n u" . my/org-roam-update-metadata))
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
        ;; BEGIN_GEMINI
        ("r" "reference note" plain
         "%?"
         :clock-in t
         :clock-resume t
         :target
         (file+head
          "%(expand-file-name (or citar-org-roam-subdir \"\")
                org-roam-directory)/${citar-citekey}.org"
          ":PROPERTIES:\n:ROAM_REFS:\n:END:\n#+title: ${citar-title}\n#+filetags: :${citar-type}:\n#+created: %U\n\n* Metadata\n- Last Modified: %U\n- Author: ${citar-author}\n- Year: ${citar-date}\n- Pages: ${citar-pages}\n- URL: ${citar-url}\n- Status: %^{Status|Reading|Completed|Abandoned|To Read}\n- Progress: %^{Progress|0|50|100}\n- Rating: %^{Rating|N/A|★☆☆☆☆|★★☆☆☆|★★★☆☆|★★★★☆|★★★★★}\n- Date Finished: %U\n\n\n* Summary\n\n* Key Definitions & Takeaways\n\n* Detailed Notes & Breakdown\n** %^{Division|Section|Chapter} 1\n\n* Atomic Concepts & Links\n\n* Quotes & Highlights\n#+begin_quote\n\n#+end_quote\n")
         :unnarrowed t)
        ;; END_GEMINI
        ("a" "article" plain "%?"
         :if-new
         (file+head "articles/${title}.org" "#+title: ${title}\n#+filetags: :article:\n")
         :immediate-finish t
         :unnarrowed t)))

;; Helper functions for updating reference nodes
;; BEGIN_GEMINI
(defun my/org-roam-update-bullet (field value)
  "Search for '- FIELD: ...' bullet point in the current buffer and replace its VALUE."
  (save-excursion
    (goto-char (point-min))
    (if (re-search-forward (format "^-[ \t]*%s:[ \t]*.*$" (regexp-quote field)) nil t)
        (replace-match (format "- %s: %s" field value))
      ;; Append field under * Metadata heading if it does not exist yet
      (when (re-search-forward "^\\* Metadata" nil t)
        (forward-line 1)
        (insert (format "- %s: %s\n" field value))))))

(defun my/org-roam-update-metadata ()
  "Interactively prompt to update Status, Rating, Date Finished, and Last Modified."
  (interactive)
  (let* ((status (completing-read "Status: " '("Reading" "Completed" "Abandoned" "To Read") nil t))
         (progress (read-string "Progress: " "0" nil t))
         (rating (completing-read "Rating: " '("N/A" "★☆☆☆☆" "★★☆☆☆" "★★★☆☆" "★★★★☆" "★★★★★") nil t))
         (timestamp (format-time-string "[%Y-%m-%d %a %H:%M]")))

    ;; Update bullet list metadata
    (my/org-roam-update-bullet "Status" status)
    (my/org-roam-update-bullet "Rating" rating)
    (my/org-roam-update-bullet "Progress" progress)
    (my/org-roam-update-bullet "Last Modified" timestamp)

    ;; Set Date Finished automatically if marked Completed
    (when (string-equal status "Completed")
      (my/org-roam-update-bullet "Date Finished" timestamp))

    ;; Update top-level property drawer
    (org-with-point-at 1
      (org-entry-put (point) "LAST_MODIFIED" timestamp))

    (message "Metadata updated.")))

(defun my/org-roam-auto-update-last-modified ()
  "Automatically update the :LAST_MODIFIED: property in top property drawer on save."
  (when (and (derived-mode-p 'org-mode)
             (buffer-file-name)
             (bound-and-true-p org-roam-directory)
             (string-prefix-p (expand-file-name org-roam-directory)
                              (expand-file-name (buffer-file-name))))
    (save-excursion
      (org-with-point-at 1
        (org-entry-put (point) "LAST_MODIFIED" (format-time-string "[%Y-%m-%d %a %H:%M]"))))))

(add-hook 'before-save-hook #'my/org-roam-auto-update-last-modified)
;; #+END_GEMINI

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
  (bib-file user-bibliography-file))

(use-package org
  :custom
  (org-cite-global-bibliography (list user-bibliography-file))
  (org-cite-insert-processor 'citar)
  (org-cite-follow-processor 'citar)
  (org-cite-activate-processor 'citar))

(use-package citar
  :ensure t
  :diminish
  :custom
  (citar-library-paths `( ,(expand-file-name "research" user-cloud-storage)))
  (citar-notes-paths `( ,(expand-file-name "research" user-cloud-storage)))
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

;;; Reading
;; TODO: Determine if Chai and Mir are worth keeping; they seem difficult to use
;; with math papers.  Chai is a package that promotes "destructive reading" to
;; fully absorb books stored as .org files in Emacs.
;; (use-package chai
;;   :vc (:url "https://github.com/yibie/chai.git"))
;;
;; (use-package chai-library
;;   :vc (:url "https://github.com/yibie/chai.git"))
;;
;; (use-package chai-library-table
;;   :vc (:url "https://github.com/yibie/chai.git"))

;; Optional: Global keybindings
;; (global-set-key (kbd "C-c l") #'chai-library-open)
;; (global-set-key (kbd "C-c b") #'chai-library-open-book)
;; (global-set-key (kbd "C-c i") #'chai-library-import)

;; Mir is a package that implements incremental reading into Emacs.  The
;; configuration below attempts to merge Mir with Chai.  Mir will be used for
;; scheduling reads, and Chai will be focused on breaking readings into
;; condensed notes.  The overall reading workflow should look like the
;; following:
;;
;; Mir -> Chai -> Org roam
;; (use-package mir
;;   :vc (:url "https://github.com/gvalson/mir.el.git")
;;   :commands (mir-import-buffer mir-extract-or-import-from-region)
;;   :custom
;;   (mir-archive-directory chai-library-directory)
;;   (mir-default-file-extension "*.org")
;;   ;; The following is adapted from a Gemini result
;;   :hook (mir-show-topic . (lambda ()
;;                             ;; Use Chai's custom faces for topics pulled from Mir
;;                             (when (and (derived-mode-p 'org-mode)
;;                                        (fboundp 'chai-mode))
;;                               (chai-mode 1))
;;
;;                             (mir-topic-minor-mode 1))))

(provide 'init-research)
;;; init-research.el ends here
