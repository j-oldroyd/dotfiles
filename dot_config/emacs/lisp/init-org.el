;;; init-org.el --- Configuration for org-mode  -*- no-byte-compile: t; lexical-binding: t; -*-

;;; Commentary:

;; My customizations for Org mode, including org-gtd. Some of this is based on
;; Emacs Bedrock.

;;; Code:
;; From Emacs Bedrock
(use-package org
  :hook ((org-mode . visual-line-mode)  ; wrap lines at word breaks
         (org-mode . flyspell-mode))    ; spell checking!

  :bind (:map global-map
              ("C-c l" . org-store-link)
              ("C-c a" . 'org-agenda)
              ("C-c c" . 'org-capture)
              ("C-c b" . 'org-switchb))

  :config
  (require 'oc-csl)                     ; citation support
  (add-to-list 'org-export-backends 'md)

  ;; Make org-open-at-point follow file links in the same window
  (setf (cdr (assoc 'file org-link-frame-setup)) 'find-file)

  ;; Make exporting quotes better
  (setq org-export-with-smart-quotes t)

  ;; Toggle TeX input method with C-\
  (setq default-input-method "TeX")
  (toggle-input-method)

  :custom
  (org-src-fontify-natively t)
  (org-preview-latex-default-process 'dvipng)
  (org-adapt-indentation t)
  (org-todo-keywords
   '((sequence "TODO(t)" "NEXT(n)" "PROG(p)" "INTR(i)"
               "|" "CANCELED(c)" "DONE(d)" "WAITING(w)" "SHELVED(s)")))
  (org-todo-keyword-faces
   '(("TODO" . org-todo)
     ("NEXT" . (:foreground "#D35400" :weight bold))
     ("INTR" . org-warning)
     ("PROG" . (:foreground "green" :weight bold))
     ("CANCELED" . (:foreground "#7F8CFD" :strike-through t :weight bold))
     ("WAITING" . (:foreground "#8E44AD" :weight bold))
     ("SHELVED" . (:foreground "gray" :weight bold))))
  (org-capture-templates
   '(("t" "Todo" entry (file org-default-notes-file)
      "* TODO %?\n%u\n%a\n" :clock-in t :clock-resume t)
     ("m" "Meeting" entry (file org-default-notes-file)
      "* MEETING with %? :MEETING:\n%t" :clock-in t :clock-resume t)
     ("d" "Diary" entry (file+datetree "~/org/diary.org")
      "* %?\n%U\n" :clock-in t :clock-resume t)
     ("i" "Idea" entry (file org-default-notes-file)
      "* %? :IDEA: \n%t" :clock-in t :clock-resume t)
     ("f" "Fleeting note" entry  (file org-default-notes-file)
      "* TODO %^{Note title}\nContext: %a\n%?" :empty-lines-before 1 )
     ("n" "Next Task" entry (file+headline org-default-notes-file "Tasks")
      "** NEXT %? \nDEADLINE: %t"))))

;; Sets up org-mode files for capture/refile.
(cond
 ((eq system-type 'darwin)
  (setq org-agenda-files '("~/Documents/org"
                           "~/Google Drive/My Drive/org"
                           "~/Google Drive/My Drive/org/roam/"
                           "~/Google Drive/My Drive/org/roam/daily/"
                           "~/Sync/beorg"))
  (setq org-default-notes-file
        (expand-file-name "~/Sync/beorg/inbox.org")))
 ((eq system-type 'gnu/linux)
  (setq org-agenda-files '("~/org"
                           "~/beorg"
                           "~/beorg/projects"
                           "~/GoogleDrive/org"
                           "~/GoogleDrive/org/roam/daily/"))
  (setq org-default-notes-file
        (expand-file-name "~/beorg/inbox.org"))))

(setq org-refile-targets
      '((nil :maxlevel . 3)
        (org-agenda-files :maxlevel . 3)))

;; Set effort estimates globally
(setq org-global-properties
      '(("Effort_ALL". "0 0:10 0:30 1:00 2:00 3:00 4:00 8:00")))

(setopt org-agenda-prefix-format '((agenda . " %i %-12:c%?-12t%-6e% s")
                                   (todo . " %i %-12:c %-6e")
                                   (tags . " %i %-12:c")
                                   (search . " %i %-12:c")))

;; Make Org mode look a little nicer.
(use-package org-modern
  :ensure t
  :hook
  ((org-mode . org-modern-mode)
   (org-agenda-finalize . org-modern-agenda)))

;;; Org exporters
(require 'ox-latex)
(add-to-list 'org-latex-classes
             '("wvwcslides"
               "\\documentclass{wvwcslides}
               [NO-DEFAULT-PACKAGES]
               [PACKAGES]
               [EXTRA]"
               ("\\section{%s}" . "\\section*{%s}")
               ("\\subsection{%s}" . "\\subsection*{%s}")
               ("\\subsubsection{%s}" . "\\subsubsection*{%s}")
               ("\\paragraph{%s}" . "\\paragraph*{%s}")
               ("\\subparagraph{%s}" . "\\subparagraph*{%s}")))


;;; GTD
;; org-gtd implements an opinionated GTD workflow into Org mode.
(use-package org-gtd
  :ensure t
  :after org
  :demand t
  :init
  ;; Suppress upgrade warnings (must be set before package loads)
  (setq org-gtd-update-ack "4.0.0")
  ;; Where org-gtd will keep its files (defaults to ~/gtd/)
  (cond ((eq system-type 'gnu/linux)
         (setq org-gtd-directory "~/beorg/gtd/"))
        ((eq system-type 'darwin)
         (setq org-gtd-directory "~/Sync/beorg/gtd/")))

  ;; A Prelude map currently lives in C-c d, and I want to use that for GTD maps
  (unbind-key "C-c d" prelude-mode-map)

  :custom
  ;; Configure TODO keyword states (options like "TODO(t)" or "DONE(d!)" are fine)
  (org-todo-keywords '((sequence "TODO(T)" "NEXT(N)" "WAIT(W)" "|"
                                 "DONE(D)" "CNCL(C)")))

  ;; Map GTD semantic states to your keywords
  (org-gtd-keyword-mapping '((todo . "TODO")
                             (next . "NEXT")
                             (wait . "WAIT")
                             (canceled . "CNCL")))

  :config
  ;; REQUIRED: Enable org-edna for project dependencies
  (org-edna-mode 1)

  ;; Add org-gtd files to your agenda (must be in :config so org-gtd-directory is defined)
  (push org-gtd-directory org-agenda-files)

  :bind
  ;; Global keybindings (work anywhere in Emacs)
  (("C-c d c" . org-gtd-capture)
   ("C-c d e" . org-gtd-engage)
   ("C-c d p" . org-gtd-process-inbox)
   ("C-c d n" . org-gtd-show-all-next)
   ("C-c d r" . org-gtd-command-center)
   ("C-c d s" . org-gtd-reflect-stuck-projects)

   ;; Keybinding for organizing items (only works in clarify buffers)
   :map org-gtd-clarify-mode-map
   ("C-c c" . org-gtd-organize)

   ;; Quick actions on tasks in agenda views (optional but recommended)
   :map org-agenda-mode-map
   ("C-c ." . org-gtd-agenda-transient)))

;;; Org babel
;; Org babel integrates coding into Org mode documents.
(org-babel-do-load-languages
 'org-babel-load-languages '((octave . t)
                             (gnuplot . t)
                             (python . t)
                             (latex . t)))

(provide init-org.el)
;;; init-org.el ends here
