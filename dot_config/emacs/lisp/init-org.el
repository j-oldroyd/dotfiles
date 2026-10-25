;;; init-org.el --- Configuration for org-mode  -*- no-byte-compile: t; lexical-binding: t; -*-

;;; Commentary:

;; My customizations for Org mode, including org-gtd. Some of this is based on
;; Emacs Bedrock.

;;; Code:
;; From Emacs Bedrock
(use-package org
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

  :hook ((org-mode . visual-line-mode)  ; wrap lines at word breaks
         (org-mode . flyspell-mode)    ; spell checking!
         (org-mode . toggle-input-method))

  :custom
  (org-src-fontify-natively t)
  (org-preview-latex-default-process 'dvipng)
  (org-adapt-indentation t)
  (org-todo-keywords
   '((sequence "TODO(t)" "NEXT(n)"
               "|" "CANCELED(c)" "DONE(d)" "WAITING(w)")))
  (org-todo-keyword-faces
   '(("TODO" . org-todo)
     ("NEXT" . (:foreground "#D35400" :weight bold))
     ("CANCELED" . (:foreground "#7F8CFD" :strike-through t :weight bold))
     ("WAITING" . (:foreground "#8E44AD" :weight bold))))
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


;; Org-transclusion
;; Org-transclusion lets you insert text from another file.  For example, I can
;; define course outcomes in a file outcomes.org and then insert them
;; programmatically into a rubric.
;; TODO: Look into setting this up.
(use-package org-transclusion
  :ensure t)

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

  :custom
  ;; Configure TODO keyword states (options like "TODO(t)" or "DONE(d!)" are fine)
  (org-todo-keywords '((sequence "TODO(T)" "NEXT(N)" "WAIT(W)" "|"
                                 "DONE(D)" "CNCL(C)")))

  ;; Map GTD semantic states to your keywords
  (org-gtd-keyword-mapping '((todo . "TODO")
                             (next . "NEXT")
                             (wait . "WAIT")
                             (canceled . "CNCL")
                             (done . "DONE")))

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

;;; Assessment
;; I use Org mode for grading homework assignments and tests.  These are helper
;; functions that I've created (through AI) to help me do so.  My goal is to
;; mimic the Gradescope workflow in Org mode.

;; Code produced using Google Gemini
(defun my/org-grading-calculate-score ()
  "Calculate points in the current subtree based on checked items with '::
+/-N'.  Returns the total points."
  (interactive)
  (save-excursion
    ;; If we are inside a code block, move out to the parent headline first
    (when (org-in-src-block-p)
      (org-back-to-heading))

    (let ((points 0))
      ;; We limit the search to the current subtree
      (org-narrow-to-subtree)
      (goto-char (point-min))

      ;; Search for lines with checkboxes and ":: value"
      (while (re-search-forward "^[ \t]*- \\[[xX]\\] .* :: \\(.*\\)" nil t)
        (setq points (+ points (string-to-number (match-string 1)))))

      (widen)
      points)))

;; TODO: Introduce calculate-score question that implements below
;; regex?  This could also be used above in my/org-grading-calculate-score.
(defun org-dblock-write:grading-score (params)
  "Dynamic block to summarize grades."
  (let ((total 0))
    (save-excursion
      (goto-char (point-min))
      (while (re-search-forward "^[ \t]*- \\[[xX]\\] .* :: \\(.*\\)" nil t)
        (setq total (+ total (string-to-number (match-string 1))))))
    (insert (format "Total Score: *%s*" total))))

(defun my/org-grading-broadcast-item (heading-name item-text points-text)
  "Add ITEM-TEXT to HEADING-NAME in all .org files in the current directory."
  ;;(interactive "sHeading Name (exact match): \nsRubric Item (e.g., '- [ ] Foo :: -1'):")
  ;; FIXME: Not quite working right
  (interactive (list (read-string "Enter heading name (exact match): " (org-get-heading))
                     (read-string "Rubric item: " "Text")
                     (read-string "Points (include +/-): " "+1")))
  (let ((files (directory-files "." t "\\.org$")))
    (dolist (file files)
      (with-current-buffer (find-file-noselect file)
        (save-excursion
          (goto-char (point-min))
          ;; Find the specific headline
          (if (re-search-forward (format "^\\*+ .*\\b%s\\b" (regexp-quote
                                                             heading-name)) nil t)
              (progn
                ;; Move to end of this item list to append the item.
                ;; This assumes that the item list is the final
                ;; component of the question subtree!
                (org-end-of-subtree)
                (insert (format "%s%s" (progn (org-insert-item t) "") item-text))
                (end-of-line)
                (insert (format " %s" points-text))
                ;; FIXME: Align isn't quite right yet when adding new item
                (org-mark-subtree)
                (align-regexp (region-beginning) (region-end)
                              "\\(\\s-*\\)::" 1 align-default-spacing t)
                (save-buffer)
                (message "Updated %s" (file-name-nondirectory file)))
            (message "Heading '%s' not found in %s" heading-name (file-name-nondirectory
                                                                  file))))))))

(defun my/grading-generate-summary-report ()
  "Generate a summary grade report from all .org files in the 'students/' directory.
 Calculates scores on the fly and prepares a buffer for PDF export."
  (interactive)
  (let ((files (directory-files "students" t "\\.org$"))
        (results '()))
    ;; 1. Iterate through all student files
    (dolist (file files)
      (with-temp-buffer
        (insert-file-contents file)
        (let ((name "Unknown")
              (total 0))
          ;; Extract Student Name
          (goto-char (point-min))
          (if (re-search-forward "^\\*+ Student: \\(.*\\)" nil t)
              (setq name (match-string 1)))

          ;; Calculate Score (Sum all checked items with ":: points")
          (goto-char (point-min))
          (while (re-search-forward "^[ \t]*- \\[[xX]\\] .* :: \\(.*\\)" nil t)
            (setq total (+ total (string-to-number (match-string 1)))))

          (push (list name total) results))))

    ;; 2. Sort results alphabetically by name
    (setq results (sort results (lambda (a b) (string< (car a) (car b)))))

    ;; 3. Create the Summary Buffer
    (let ((buffer (get-buffer-create "*Grade Summary*")))
      (with-current-buffer buffer
        (erase-buffer)
        ;; Insert Header for PDF Export
        (insert "#+TITLE: Final Grade Report\n")
        (insert "#+DATE: " (format-time-string "%Y-%m-%d") "\n")
        (insert "#+OPTIONS: toc:nil\n")
        (insert "#+LATEX_HEADER: \\usepackage{booktabs}\n\n") ;; Better table formatting

        (insert "* Class Summary\n\n")

        ;; Insert the Table with LaTeX attributes
        (insert "#+ATTR_LATEX: :environment tabular :align l r :booktabs t\n")
        (insert "| Student Name | Total Score |\n")
        (insert "|--------------+-------------|\n")

        (dolist (entry results)
          (insert (format "| %s | %s |\n" (car entry) (cadr entry))))

        ;; Align the table and enable Org mode
        (org-mode)
        (org-table-align)
        (goto-char (point-min)))

      ;; Display the buffer
      (switch-to-buffer buffer))))

(defun my/grading-distribution-histogram (&optional bin-size)
  "Generate a grade distribution histogram (frequency table) and Gnuplot header.
 BIN-SIZE defaults to 5 if not provided."
  (interactive "nBin size (default 5): ")
  (let ((size (if (or (not bin-size) (zerop bin-size)) 5 bin-size))
        (files (directory-files "students" t "\\.org$"))
        (scores '())
        (max-score 0)
        (frequencies (make-hash-table :test 'eq)))

    ;; 1. Collect all scores
    (dolist (file files)
      (with-temp-buffer
        (insert-file-contents file)
        (let ((total 0))
          ;; Sum checked items
          (goto-char (point-min))
          (while (re-search-forward "^[ \t]*- \\[[xX]\\] .* :: \\(.*\\)" nil t)
            (setq total (+ total (string-to-number (match-string 1)))))
          (push total scores)
          (setq max-score (max max-score total)))))

    ;; 2. Calculate Frequencies
    (dolist (score scores)
      (let* ((bucket-floor (* (/ score size) size))
             (current-count (gethash bucket-floor frequencies 0)))
        (puthash bucket-floor (1+ current-count) frequencies)))

    ;; 3. Output Table and Plot Header
    (with-current-buffer (get-buffer-create "*Grade Distribution*")
      (erase-buffer)
      ;; Gnuplot configuration for a histogram style bar chart
      (insert "#+TITLE: Grade Distribution\n")
      (insert "#+ATTR_LATEX: :width 10cm\n")
      (insert (format "#+PLOT: title:\"Grade Distribution (Bin Size: %d)\" ind:1 type:2d with:boxes set:\"style fill solid\" set:\"yrange [0:]\"\n" size))

      (insert "| Range | Frequency |\n")
      (insert "|-------+-----------|\n")

      ;; Loop through bins from 0 to max-score
      (let ((i 0))
        (while (<= i max-score)
          (let ((count (gethash i frequencies 0))
                (range-label (format "%d-%d" i (+ i (- size 1)))))
            (insert (format "| %s | %d |\n" range-label count)))
          (setq i (+ i size))))

      (org-mode)
      (org-table-align)
      (display-buffer (current-buffer))
      (message "Press 'C-c \" g' inside the table to generate the graph."))))

(defun my/grading-master-report (&optional bin-size)
  "Generate a comprehensive Grade Report with distribution graph and student table.
      BIN-SIZE defaults to 5."
  (interactive "nBin size for histogram (default 5): ")
  (let* ((size (if (or (not bin-size) (zerop bin-size)) 5 bin-size))
         (files (directory-files "students" t "\\.org$"))
         (student-data '()) ;; List of (Name . Score)
         (frequencies (make-hash-table :test 'eq))
         (max-score 0))

    ;; --- 1. Data Collection ---
    (dolist (file files)
      (with-temp-buffer
        (insert-file-contents file)
        (let ((name "Unknown") (total 0))
          ;; Extract Name
          (goto-char (point-min))
          (if (re-search-forward "^\\*+ Student: \\(.*\\)" nil t)
              (setq name (match-string 1)))
          ;; Calculate Score
          (goto-char (point-min))
          (while (re-search-forward "^[ \t]*- \\[[xX]\\] .* :: \\(.*\\)" nil t)
            (setq total (+ total (string-to-number (match-string 1)))))

          (push (cons name total) student-data)
          (setq max-score (max max-score total)))))

    ;; --- 2. Statistics & Binning ---
    ;; Sort students alphabetically
    (setq student-data (sort student-data (lambda (a b) (string< (car a) (car b)))))

    ;; Fill histogram buckets
    (dolist (item student-data)
      (let* ((score (cdr item))
             (bucket-floor (* (/ score size) size))
             (current-count (gethash bucket-floor frequencies 0)))
        (puthash bucket-floor (1+ current-count) frequencies)))

    ;; --- 3. Generate Report Buffer ---
    (let ((buffer (get-buffer-create "*Master Course Report*")))
      (with-current-buffer buffer
        (erase-buffer)

        ;; Header
        (insert "#+TITLE: Course Grade Report\n")
        (insert "#+DATE: " (format-time-string "%Y-%m-%d") "\n")
        (insert "#+LATEX_HEADER: \\usepackage{booktabs}\n")
        (insert "#+OPTIONS: toc:nil\n\n")

        ;; Section 1: Distribution Graph
        (insert "* Grade Distribution\n")
        (insert (format "Bin size: %d points\n\n" size))

        (insert "#+NAME: distribution-table\n")
        (insert "| Range | Frequency |\n")
        (insert "|-------+-----------|\n")

        (let ((i 0))
          (while (<= i max-score)
            (let ((count (gethash i frequencies 0))
                  (range-label (format "%d-%d" i (+ i (- size 1)))))
              (insert (format "| %s | %d |\n" range-label count)))
            (setq i (+ i size))))

        (insert "\n#+BEGIN_SRC gnuplot :var data=distribution-table :file grade_dist.png :results graphics file :exports results\n")
        (insert "set title 'Grade Distribution'\n")
        (insert "set style data histograms\n")
        (insert "set style fill solid\n")
        (insert "set yrange [0:*]\n")
        (insert "set boxwidth 0.75\n")
        (insert "set xlabel 'Score Range'\n")
        (insert "set ylabel 'Frequency'\n")
        (insert "plot data using 2:xtic(1) notitle\n")
        (insert "#+END_SRC\n\n")

        ;; Section 2: Student Table
        (insert "* Student Scores\n")
        (insert "#+ATTR_LATEX: :environment tabular :align l r :booktabs t\n")
        (insert "| Student Name | Total Score |\n")
        (insert "|--------------+-------------|\n")
        (dolist (item student-data)
          (insert (format "| %s | %s |\n" (car item) (cdr item))))

        (org-mode)
        (org-table-align)
        (goto-char (point-min)))

      (switch-to-buffer buffer)
      (message "Report generated! Press 'C-c C-e l o' to export to PDF."))))

(provide 'init-org)
;;; init-org.el ends here
