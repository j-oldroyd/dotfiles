;;; init-grading.el --- Configuration for grading workflow -*- no-byte-compile: t; lexical-binding: t; -*-

;;; Commentary:

;; Customizations that support grading in Org mode.  This is mostly
;; Claude-produced code at this point.

;;; Code:
(require 'org)
(require 'cl-lib)
(require 'subr-x)

;;; Rubrics
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
  :type 'file)

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
                     (cdar result))))))))))
  (mapcar (lambda (q) (cons (car q) (reverse (cdr q))))
          (nreverse result)))

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
Call with point on the exam heading.  This replaces the simpler
version in grading.el."
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
  :type 'regexp)

(defcustom grading-questions
  '(("Q1" ("LO1") 10)
    ("Q2" ("LO1" "LO2") 10)
    ("Q3" ("LO3") 15))
  "Question template used by `grading-add-student'.
Each entry is (TITLE (OUTCOME-TAGS...) MAX-POINTS)."
  :type '(repeat (list string (repeat string) integer)))

(defcustom grading-student-level 2
  "Outline level of the headings that name students."
  :type 'integer)

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

(defun grading-add-student (name)
  "Add a heading for NAME, with the questions in `grading-questions', below point."
  (interactive "sStudent: ")
  (let* ((level (1+ (or (org-current-level) 0)))
         (stars (make-string level ?*))
         (sub (make-string (1+ level) ?*)))
    (org-end-of-subtree t t)
    (insert (format "\n%s %s\n" stars name))
    (dolist (q grading-questions)
      (insert (format "%s %s :%s:\n:PROPERTIES:\n:SCORE: \n:MAX: %d\n:END:\n"
                      sub (car q) (string-join (cadr q) ":") (nth 2 q))))))

(provide 'init-grading)
;;; init-grading.el ends here
