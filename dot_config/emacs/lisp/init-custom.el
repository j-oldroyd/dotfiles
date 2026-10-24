;;; init-custom.el --- Configuration of general, custom variables -*- no-byte-compile: t; lexical-binding: t; -*-

;;; Commentary:

;; This file keeps track of custom variables I want to set Emacs-wide.  These
;; include built-in variables (many of which can be managed with the emacs
;; "package") and personal variables that are created here and have values
;; stored in a custom.el file that is not tracked.


;;; Emacs
(use-package emacs
  :ensure nil
  :custom
  (user-mail-address user-semi-professional-email))

;;; User variables
(defgroup user nil
  "User-facing variables."
  :prefix "user-")

;; Library file
(defcustom user-bibliography-file ""
  "Load path for user bibliography file.  This is assumed to be a .bib file
that is managed by some external program (such as Zotero)."
  :type 'file
  :group 'user)

;; Mail variables
(defcustom user-mu4e-path "/usr/local/share/emacs/site-lisp/mu4e"
  "Load path for mu4e mail client.  Defaults to the default location for
build from source."
  :type 'directory
  :group 'user)

(defcustom user-professional-email ""
  "Employer email address for use in mu4e."
  :type 'string
  :group 'user)

(defcustom user-semi-professional-email ""
  "Semi-professional (i.e., not employer-owned) email address for use in
mu4e."
  :type 'string
  :group 'user)

(defcustom user-personal-email ""
  "Personal email address for use in mu4e."
  :type 'string
  :group 'user)

(defcustom user-mail-names nil
  "Alternative names for org-msg to use when composing replies.  This is
sent to `org-msg-recipient-names' and so it should be a list of cons
cells."
  ;; :type '(alist :key-type string :value-type string)
  :type '(repeat (cons (string :tag "Recipient mail")
                       (string :tag "Recipient display name")))
  :group 'user)

(provide 'init-custom)
;;; init-custom.el ends here
