;;; init-grading.el --- Configuration for grading workflow -*- no-byte-compile: t; lexical-binding: t; -*-

;;; Commentary:

;; Customizations that support grading in Org mode.  This is mostly
;; Claude-produced code at this point.

;;; Code:
(use-package org
  :ensure nil)
(require 'cl-lib)
(require 'subr-x)

;;; Rubrics
(defgroup grading nil
  "Grading and learning-outcome tracking in Org mode."
  :group 'org
  :prefix "grading-")

;; Layout assumed (see rubrics.org and gradebook-template.org):
;;
;;   rubrics.org         * Q1                       <- question
;;                       ** Criterion text :LO1:    <- criterion, with
;;                          :RUBRIC_ID: and :MAX:
;;
;;   gradebook           * Exam 1
;;                       ** Student name            <- `grading-student-level'
;;                       *** Q1                     <- same title as master
;;                       **** Criterion text :LO1:  <- :RUBRIC_ID:, :MAX:, :SCORE:
;;
;; `grading-sync-rubric' copies title, tags and :MAX: from the master to
;; every student's criteria, adds criteria that are new, and never touches
;; :SCORE: or the entry body (your feedback).

(defcustom grading-rubric-file "rubrics.org"
  "Master rubric file, relative to the gradebook's directory."
  :type 'file
  :group 'grading)

(defun grading--rubric ()
  "Return an alist (QUESTION . CRITERIA) read from `grading-rubric-file'.
Each criterion is a plist with keys :id, :title, :tags and :max."
  (let ((file (expand-file-name grading-rubric-file))
        result)
    (with-current-buffer (find-file-noselect file)
      (save-excursion
        (save-restriction
          (widen)
          (org-map-entries
           (lambda ()
             (cond
              ((= (org-current-level) 1)
               (push (list (org-get-heading t t t t)) result))
              ((and result (org-entry-get nil "RUBRIC_ID"))
               (push (list :id (org-entry-get nil "RUBRIC_ID")
                           :title (org-get-heading t t t t)
                           :tags (org-get-tags nil t)
                           :max (org-entry-get nil "MAX"))
                     (cdar result)))))))))
    (mapcar (lambda (q) (cons (car q) (reverse (cdr q))))
            (nreverse result))))

(defun grading--criterion-string (crit level)
  "Return Org text for criterion CRIT as a heading at LEVEL, with empty score."
  (let ((tags (plist-get crit :tags)))
    (format "%s %s%s\n:PROPERTIES:\n:RUBRIC_ID: %s\n:SCORE: \n:MAX: %s\n:END:\n"
            (make-string level ?*)
            (plist-get crit :title)
            (if tags (format " :%s:" (string-join tags ":")) "")
            (plist-get crit :id)
            (or (plist-get crit :max) 0))))

(defun grading--question-string (question crits level)
  "Return Org text for QUESTION at LEVEL with all of CRITS beneath it."
  (concat (format "%s %s\n" (make-string level ?*) question)
          (mapconcat (lambda (c) (grading--criterion-string c (1+ level)))
                     crits "")))

(defun grading--marker ()
  "Return a marker at point that advances when text is inserted there."
  (let ((m (point-marker)))
    (set-marker-insertion-type m t)
    m))

(defun grading--insert-at-subtree-end (string)
  "Insert STRING at the end of the current subtree, starting on a fresh line."
  (org-end-of-subtree t t)
  (unless (bolp) (insert "\n"))
  (insert string))

(defun grading-add-student (name)
  "Add a heading for NAME below the current heading, built from the master rubric.
Call with point on the exam heading.  See also
`grading-add-student-from-template' for the simpler, template-based
version."
  (interactive "sStudent: ")
  (let ((level (1+ (org-current-level))))
    (grading--insert-at-subtree-end
     (concat (format "%s %s\n" (make-string level ?*) name)
             (mapconcat (lambda (q)
                          (grading--question-string (car q) (cdr q) (1+ level)))
                        (grading--rubric) "")))))

(defun grading--update-criterion (crit)
  "Update the entry at point from CRIT, leaving :SCORE: and the body alone."
  (org-edit-headline (plist-get crit :title))
  (org-set-tags (plist-get crit :tags))
  (org-set-property "MAX" (format "%s" (or (plist-get crit :max) 0))))

(defun grading-sync-rubric ()
  "Propagate the master rubric to every student, preserving scores and feedback.
Criteria are matched by :RUBRIC_ID:.  New criteria are appended to the end of
the matching question.  Criteria that no longer exist in the master are left
alone and listed in the *grading-sync* buffer."
  (interactive)
  (let ((rubric (grading--rubric))
        (qlevel (1+ grading-student-level))
        markers orphans (updated 0) (added 0))
    (save-excursion
      (save-restriction
        (widen)
        ;; Collect question entries first, so edits don't disturb the scan.
        (org-map-entries
         (lambda ()
           (when (and (= (org-current-level) qlevel)
                      (assoc (org-get-heading t t t t) rubric))
             (push (grading--marker) markers))))
        (dolist (m (nreverse markers))
          (goto-char m)
          (let* ((qname (org-get-heading t t t t))
                 (student (grading--student-at-point))
                 (crits (cdr (assoc qname rubric)))
                 (existing (make-hash-table :test #'equal))
                 (seen (make-hash-table :test #'equal)))
            (org-map-entries
             (lambda ()
               (let ((id (org-entry-get nil "RUBRIC_ID")))
                 (when id (puthash id (grading--marker) existing))))
             nil 'tree)
            (dolist (c crits)
              (let* ((id (plist-get c :id))
                     (cm (gethash id existing)))
                (puthash id t seen)
                (if cm
                    (progn (goto-char cm)
                           (grading--update-criterion c)
                           (cl-incf updated))
                  (goto-char m)
                  (grading--insert-at-subtree-end
                   (grading--criterion-string c (1+ qlevel)))
                  (cl-incf added))))
            (maphash (lambda (id _cm)
                       (unless (gethash id seen)
                         (push (format "%s / %s / %s" student qname id) orphans)))
                     existing)))))
    (when orphans
      (with-current-buffer (get-buffer-create "*grading-sync*")
        (erase-buffer)
        (insert "Criteria no longer in the master rubric (left untouched):\n")
        (dolist (o (nreverse orphans)) (insert "  " o "\n"))
        (display-buffer (current-buffer))))
    (message "Rubric sync: %d criteria updated, %d added%s"
             updated added
             (if orphans (format ", %d orphaned" (length orphans)) ""))))

;;; Outcomes
;; Convention: each question is a heading with a :SCORE: and :MAX:
;; property and outcome tags such as :LO1:LO3:.  Its parent heading is
;; the student.  Questions with an empty :SCORE: are treated as ungraded.

(defcustom grading-outcome-regexp "^LO[0-9]+$"
  "Tags matching this regexp are treated as learning outcomes."
  :type 'regexp
  :group 'grading)

(defcustom grading-questions
  '(("Q1" ("LO1") 10)
    ("Q2" ("LO1" "LO2") 10)
    ("Q3" ("LO3") 15))
  "Question template used by `grading-add-student'.
Each entry is (TITLE (OUTCOME-TAGS...) MAX-POINTS)."
  :type '(repeat (list string (repeat string) integer))
  :group 'grading)

(defcustom grading-student-level 2
  "Outline level of the headings that name students."
  :type 'integer
  :group 'grading)

(defun grading--student-at-point ()
  "Return the title of the ancestor heading at `grading-student-level'."
  (save-excursion
    (when (and (org-current-level)
               (>= (org-current-level) grading-student-level))
      (while (and (> (org-current-level) grading-student-level)
                  (org-up-heading-safe)))
      (org-get-heading t t t t))))

(defun grading--pct (score max)
  "Return SCORE/MAX as a percentage string, or \"\" if MAX is not positive."
  (if (> max 0) (format "%.1f" (* 100.0 (/ (float score) max))) ""))

(defun grading--records ()
  "Return a list of (STUDENT OUTCOME SCORE MAX) for scored entries."
  (let (records)
    (org-map-entries
     (lambda ()
       (let* ((score (string-to-number (org-entry-get nil "SCORE")))
              (mx (string-to-number (or (org-entry-get nil "MAX") "0")))
              (student (grading--student-at-point))
              (los (cl-remove-if-not
                    (lambda (tag) (string-match-p grading-outcome-regexp tag))
                    (org-get-tags nil t))))
         (dolist (lo los)
           (push (list student lo score mx) records))))
     "SCORE={.}")
    (nreverse records)))

(defun grading-outcome-summary ()
  "Class-wide totals per outcome, as rows suitable for an Org table."
  (let ((totals (make-hash-table :test #'equal))
        rows)
    (dolist (r (grading--records))
      (pcase-let ((`(,_ ,lo ,score ,mx) r))
        (let ((cell (gethash lo totals (list 0 0))))
          (puthash lo (list (+ (car cell) score) (+ (cadr cell) mx)) totals))))
    (maphash (lambda (lo cell)
               (push (list lo (car cell) (cadr cell)
                           (grading--pct (car cell) (cadr cell)))
                     rows))
             totals)
    (append '(("Outcome" "Score" "Max" "%") hline)
            (sort rows (lambda (a b) (string< (car a) (car b)))))))

(defun grading-outcome-by-student ()
  "Percentage per student (rows) per outcome (columns)."
  (let* ((records (grading--records))
         (los (sort (delete-dups (mapcar #'cadr records)) #'string<))
         (students (delete-dups (delq nil (mapcar #'car records)))))
    (append
     (list (cons "Student" los) 'hline)
     (mapcar
      (lambda (s)
        (cons s
              (mapcar
               (lambda (lo)
                 (let ((sc 0) (mx 0))
                   (dolist (r records)
                     (when (and (equal (car r) s) (equal (cadr r) lo))
                       (cl-incf sc (nth 2 r))
                       (cl-incf mx (nth 3 r))))
                   (grading--pct sc mx)))
               los)))
      students))))

(defun grading-insert-outcome-summary ()
  "Insert the class-wide outcome summary as an Org table at point."
  (interactive)
  (insert (orgtbl-to-orgtbl (grading-outcome-summary) nil) "\n")
  (forward-line -1)
  (org-table-align))

(defun grading-add-student-from-template (name)
  "Add a heading for NAME, with the questions in `grading-questions', below point.
This is the simple template-based version.  `grading-add-student' (defined
above) builds the student from the master rubric instead."
  (interactive "sStudent: ")
  (let* ((level (1+ (or (org-current-level) 0)))
         (stars (make-string level ?*))
         (sub (make-string (1+ level) ?*)))
    (org-end-of-subtree t t)
    (insert (format "\n%s %s\n" stars name))
    (dolist (q grading-questions)
      (insert (format "%s %s :%s:\n:PROPERTIES:\n:SCORE: \n:MAX: %d\n:END:\n"
                      sub (car q) (string-join (cadr q) ":") (nth 2 q))))))


;;; Exports
;; Builds one report per student (overall comments, each question and
;; criterion with score/max and your comment, plus a learning-outcome
;; summary) and exports it to PDF with ox-latex.  Comments are ordinary Org
;; text, so LaTeX math such as $\det A \neq 0$ or \[ ... \] works.
;;
;; The report is generated from the student's subtree only, so no other
;; student's data can leak into it.  Reports are written to
;; `grading-feedback-directory' and can be regenerated at any time.

(defcustom grading-feedback-directory "feedback/"
  "Directory for generated feedback files, relative to the gradebook."
  :type 'directory)

(defcustom grading-feedback-title nil
  "Title for feedback documents.  Nil means use the gradebook's #+TITLE."
  :type '(choice (const :tag "Gradebook title" nil) string))

(defcustom grading-feedback-header
  "#+LATEX_HEADER: \\usepackage[margin=1in]{geometry}
#+LATEX_HEADER: \\usepackage{amsmath,amssymb,amsthm}
#+OPTIONS: toc:nil num:nil author:nil date:nil ^:nil"
  "Org export keywords placed at the top of every feedback document."
  :type 'string)

(defcustom grading-outcome-descriptions nil
  "Alist of (TAG . DESCRIPTION) used in the outcome summary.
For example: ((\"LO1\" . \"Verify that a set is a basis\"))."
  :type '(alist :key-type string :value-type string))

;;;; Reading a student's subtree

(defun grading--entry-body ()
  "Return the text of the entry at point, after its drawers and before children."
  (save-excursion
    (org-back-to-heading t)
    (let ((end (save-excursion (outline-next-heading) (point)))
          (start (progn (org-end-of-meta-data t) (point))))
      (if (< start end)
          (string-trim (buffer-substring-no-properties start end))
        ""))))

(defun grading--student-data ()
  "Return a plist describing the student whose subtree contains point.
Keys: :name, :comment, and :questions, an alist (QUESTION . CRITERIA)
where each criterion is a plist with :title :score :max :tags :comment."
  (save-excursion
    (unless (and (org-current-level)
                 (>= (org-current-level) grading-student-level))
      (user-error "Point is not inside a student heading"))
    (while (and (> (org-current-level) grading-student-level)
                (org-up-heading-safe)))
    (org-back-to-heading t)
    (let ((name (org-get-heading t t t t))
          (comment (grading--entry-body))
          (qlevel (1+ grading-student-level))
          questions)
      (org-map-entries
       (lambda ()
         (cond
          ((= (org-current-level) qlevel)
           (push (list (org-get-heading t t t t)) questions))
          ((and questions (org-entry-get nil "RUBRIC_ID"))
           (let ((score (org-entry-get nil "SCORE"))
                 (mx (org-entry-get nil "MAX")))
             (push (list :title (org-get-heading t t t t)
                         :score (and score (not (string-blank-p score))
                                     (string-to-number score))
                         :max (string-to-number (or mx "0"))
                         :tags (org-get-tags nil t)
                         :comment (grading--entry-body))
                   (cdar questions))))))
       nil 'tree)
      (list :name name
            :comment comment
            :questions (mapcar (lambda (q) (cons (car q) (reverse (cdr q))))
                               (nreverse questions))))))

;;;; Building the report

(defun grading--num (x)
  "Format number X compactly (3.0 -> \"3\", 2.5 -> \"2.5\")."
  (format "%g" x))

(defun grading--criteria-of (data)
  "Return all criteria plists in student DATA."
  (cl-loop for q in (plist-get data :questions) append (cdr q)))

(defun grading--sum (crits key)
  "Sum KEY (:score or :max) over the graded criteria in CRITS."
  (cl-loop for c in crits
           when (plist-get c :score)
           sum (plist-get c key)))

(defun grading--score-string (score mx)
  "Return \"SCORE/MX\", or \"not graded\" when SCORE is nil."
  (if score
      (format "%s/%s" (grading--num score) (grading--num mx))
    "not graded"))

(defun grading--outcome-rows (crits)
  "Return a sorted list of (OUTCOME SCORE MAX) from the graded CRITS."
  (let (alist)
    (dolist (c crits)
      (when (plist-get c :score)
        (dolist (tag (plist-get c :tags))
          (when (string-match-p grading-outcome-regexp tag)
            (let ((cell (assoc tag alist)))
              (unless cell
                (setq cell (list tag 0 0))
                (push cell alist))
              (cl-incf (nth 1 cell) (plist-get c :score))
              (cl-incf (nth 2 cell) (plist-get c :max)))))))
    (sort alist (lambda (a b) (string< (car a) (car b))))))

(defun grading--feedback-org (data title)
  "Return the Org source of the feedback report for student DATA."
  (let* ((all (grading--criteria-of data))
         (total (grading--sum all :score))
         (mx (grading--sum all :max)))
    (with-temp-buffer
      (insert (format "#+TITLE: %s\n%s\n\n" title grading-feedback-header))
      (insert (format "*Student:* %s\n\n*Total:* %s/%s (%s%%)\n\n"
                      (plist-get data :name)
                      (grading--num total) (grading--num mx)
                      (grading--pct total mx)))
      (unless (string-empty-p (plist-get data :comment))
        (insert "* Overall comments\n" (plist-get data :comment) "\n\n"))
      (dolist (q (plist-get data :questions))
        (let ((crits (cdr q)))
          (insert (format "* %s (%s/%s)\n" (car q)
                          (grading--num (grading--sum crits :score))
                          (grading--num (grading--sum crits :max))))
          (dolist (c crits)
            (insert (format "** %s --- %s\n"
                            (plist-get c :title)
                            (grading--score-string (plist-get c :score)
                                                   (plist-get c :max))))
            (unless (string-empty-p (plist-get c :comment))
              (insert (plist-get c :comment) "\n"))
            (insert "\n"))))
      (let ((rows (grading--outcome-rows all)))
        (when rows
          (insert "* Learning outcomes\n")
          (dolist (r rows)
            (let ((desc (cdr (assoc (car r) grading-outcome-descriptions))))
              (insert (format "- %s :: %s/%s (%s%%)\n"
                              (if desc (format "%s: %s" (car r) desc) (car r))
                              (grading--num (nth 1 r))
                              (grading--num (nth 2 r))
                              (grading--pct (nth 1 r) (nth 2 r))))))
          (insert "\n")))
      (buffer-string))))

;;;; Writing and exporting

(defun grading--gradebook-title ()
  "Return the title to use on feedback documents."
  (or grading-feedback-title
      (car (cdr (assoc "TITLE" (org-collect-keywords '("TITLE")))))
      "Feedback"))

(defun grading--write-feedback (data title)
  "Write the Org feedback file for student DATA and return its path."
  (let* ((dir (expand-file-name grading-feedback-directory))
         (slug (string-trim
                (replace-regexp-in-string
                 "[^[:alnum:]]+" "-" (downcase (plist-get data :name)))
                "-+" "-+"))
         (file (expand-file-name (concat slug ".org") dir)))
    (make-directory dir t)
    (with-temp-file file
      (insert (grading--feedback-org data title)))
    file))

(defun grading--export-feedback-file (file)
  "Export the Org FILE to PDF with ox-latex and return the PDF's path."
  (let ((buf (find-file-noselect file)))
    (unwind-protect
        (with-current-buffer buf
          (org-latex-export-to-pdf))
      (kill-buffer buf))))

;;;###autoload
(defun grading-export-student ()
  "Export a PDF of feedback for the student whose subtree contains point."
  (interactive)
  (let* ((data (grading--student-data))
         (title (grading--gradebook-title))
         (ungraded (cl-count-if-not (lambda (c) (plist-get c :score))
                                    (grading--criteria-of data))))
    (when (or (zerop ungraded)
              (y-or-n-p (format "%d criteria are not graded yet.  Export anyway? "
                                ungraded)))
      (let ((pdf (grading--export-feedback-file
                  (grading--write-feedback data title))))
        (message "Wrote %s" pdf)
        pdf))))

;;;###autoload
(defun grading-export-all-students ()
  "Export a feedback PDF for every student heading in the buffer.
Headings at `grading-student-level' with no rubric criteria beneath them
(such as an Outcomes or Summary section) are skipped."
  (interactive)
  (let ((title (grading--gradebook-title))
        markers (done 0) (incomplete 0))
    (save-excursion
      (save-restriction
        (widen)
        (org-map-entries
         (lambda ()
           (when (= (org-current-level) grading-student-level)
             (push (point-marker) markers))))
        (dolist (m (nreverse markers))
          (goto-char m)
          (let ((data (grading--student-data)))
            (when (cl-some #'cdr (plist-get data :questions))
              (when (cl-some (lambda (c) (null (plist-get c :score)))
                             (grading--criteria-of data))
                (cl-incf incomplete))
              (grading--export-feedback-file
               (grading--write-feedback data title))
              (cl-incf done))))))
    (message "Exported feedback for %d students%s" done
             (if (> incomplete 0)
                 (format " (%d with ungraded criteria)" incomplete)
               ""))))

(provide 'init-grading)
;;; init-grading.el ends here
