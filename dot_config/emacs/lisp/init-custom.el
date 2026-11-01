;;; init-custom.el --- Configuration of general, custom variables -*- no-byte-compile: t; lexical-binding: t; -*-

;;; Commentary:

;; This file keeps track of custom variables I want to set Emacs-wide.  These
;; are personal variables that are created here and have values stored in a
;; custom.el file that is not tracked.
;;
;; Order matters: the defcustoms below must exist before anything reads them,
;; and custom.el is loaded *after* this file.  Settings that depend on values
;; stored in custom.el therefore live in `my/apply-custom-values', which
;; post-init.el should call right after loading `custom-file':
;;
;;   (require 'init-custom)
;;   (when (file-exists-p custom-file)
;;     (load custom-file 'noerror 'nomessage))
;;   (my/apply-custom-values)

;;; Code:

;;; User variables
(defgroup my-config nil
  "Personal configuration variables."
  :prefix "my/")

;; Library file
(defcustom my/bibliography-file ""
  "Load path for user bibliography file.
This is assumed to be a .bib file that is managed by some external program
\(such as Zotero)."
  :type 'file
  :group 'my-config)

;; Mail variables
(defcustom my/mu4e-path "/usr/local/share/emacs/site-lisp/mu4e"
  "Load path for mu4e mail client.
Defaults to the default location for a build from source."
  :type 'directory
  :group 'my-config)

(defcustom my/professional-email ""
  "Employer email address for use in mu4e."
  :type 'string
  :group 'my-config)

(defcustom my/semi-professional-email ""
  "Semi-professional (i.e., not employer-owned) email address for mu4e."
  :type 'string
  :group 'my-config)

(defcustom my/personal-email ""
  "Personal email address for use in mu4e."
  :type 'string
  :group 'my-config)

(defcustom my/mail-names nil
  "Alternative names for org-msg to use when composing replies.
This is sent to `org-msg-recipient-names' and so it should be a list of cons
cells."
  :type '(repeat (cons (string :tag "Recipient mail")
                       (string :tag "Recipient display name")))
  :group 'my-config)

;; BEGIN_CLAUDE
;;; Settings that depend on values from custom.el
(defun my/apply-custom-values ()
  "Apply settings that depend on values stored in `custom-file'.
Call this after `custom-file' has been loaded."
  (unless (string-empty-p my/semi-professional-email)
    (setopt user-mail-address my/semi-professional-email)))
;; END_CLAUDE

(provide 'init-custom)
;;; init-custom.el ends here
