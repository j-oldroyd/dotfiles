;;; init-mail.el --- Mail settings using mu4e -*- no-byte-compile: t; lexical-binding: t; -*-

;;; Commentary:

;; This file sets up mu4e, the Emacs mail client.  This is based on the CLI tool mu.

;;; Code:

;; `mu4e' is installed with mu, and so we load it from where it's installed.
;; This value is stored in the custom variable `user-mu4e-path'.  We also need
;; to make sure Elpaca doesn't mess with it since Elpaca can't find it on
;; (M)ELPA.  We disable Elpaca for `nano-mu4e' as well, as it depends on `mu4e'
;; and then Elpaca tries to find it again.
(use-package mu4e
  :ensure nil
  :elpaca nil
  :load-path user-mu4e-path
  ;; :vc t ;; adds symlink to elpa dir
  :bind (("C-c M" . mu4e))
  :config
  ;; mu4e likes to open in full frame, so... don't do that. Taken from
  ;;
  ;; https://irreal.org/blog/?p=11323
  ;; FIXME: This causes an error on startup since mu4e isn't loaded yet
  (add-to-list 'display-buffer-alist
               `(,(regexp-quote mu4e-main-buffer-name)
                 display-buffer-same-window))
  ;; Enable message tagging
  (add-to-list 'mu4e-headers-actions
               '("Tag message" . mu4e-action-retag-message))
  (add-to-list 'mu4e-view-actions
               '("Tag message" . mu4e-action-retag-message))

  ;; Run mu4e-mailing-list-info-refresh to update mailing lists after change
  (add-to-list 'mu4e-user-mailing-lists '(:list-id "tex-live.tug.org" :name "TUG"))
  ;; Enable message tagging
  (add-to-list 'mu4e-headers-actions
               '("Tag message" . mu4e-action-retag-message))
  (add-to-list 'mu4e-view-actions
               '("Tag message" . mu4e-action-retag-message))
  ;; Line numbers interfere with image displays in mu4e-view-mode, so turn them
  ;; off.
  :hook (mu4e-view-mode . (lambda ()
                            (display-line-numbers-mode -1))))

;; Nice looking minor mode for nano-mu4e
(use-package nano-mu4e
  :defer t
  :ensure nil
  :elpaca nil
  :after mu4e
  :vc (:url "https://github.com/rougier/nano-mu4e.git"
            :rev :newest))

;; For sending mail.
(require 'smtpmail)

;; This is installed with your favorite package manager, such as Homebrew.
(setq mu4e-mu-binary (executable-find "mu"))

;; This command is called to sync imap servers:
(setq mu4e-get-mail-command (concat (executable-find "mbsync") " -a"))
;; How often to call it in seconds:
(setq mu4e-update-interval 300)

;; save attachment to desktop by default
;; or another choice of yours:
(setq mu4e-attachment-dir "~/Attachments/")

;; Rename files when moving - needed for mbsync:
(setq mu4e-change-filenames-when-moving t)

;; Change HTML display for dark color schemes
(setq shr-color-visible-luminance-min 80)

;; Prevent line breaks in emails.  This can look weird on mobile devices.
(setq mu4e-compose-format-flowed t)

(with-eval-after-load 'mu4e
  (cond
   ((eq system-type 'darwin)
    (setq send-mail-function 'sendmail-send-it
          sendmail-program "/opt/homebrew/bin/msmtp"
          mail-specify-envelope-from t
          message-sendmail-envelope-from 'header
          mail-envelope-from 'header)
    (setq mu4e-contexts
          `( ,(make-mu4e-context
               :name "gmail"
               :match-func (lambda (msg)
                             (when msg
                               (string-prefix-p "/gmail" (mu4e-message-field msg :maildir))))
               :vars '((mu4e-trash-folder . "/gmail/[Gmail]/Trash")
                       (mu4e-refile-folder . "/gmail/[Gmail]/Archive")
                       (user-mail-address . user-semi-professional-email)
                       (mu4e-maildir-shortcuts . ( ("/gmail/INBOX" . ?i)))))
             ,(make-mu4e-context
               :name "wvwc-mail"
               :match-func (lambda (msg)
                             (when msg
                               (string-prefix-p "/gmail" (mu4e-message-field msg :maildir))))
               :vars '((mu4e-trash-folder . "/wvwc-mail/[wvwc-mail]/Trash")
                       (mu4e-refile-folder . "/wvwc-mail/[wvwc-mail]/Archive")
                       (user-mail-address . user-professional-email)
                       (mu4e-maildir-shortcuts . ( ("/wvwc-mail/INBOX" . ?i)))))
             ,(make-mu4e-context
               :name "icloud"
               :match-func (lambda (msg)
                             (when msg
                               (string-prefix-p "/icloud" (mu4e-message-field msg :maildir))))
               :vars '((mu4e-trash-folder . "/icloud/Deleted Messages")
                       (mu4e-refile-folder . "/icloud/Archive")
                       (user-mail-address . user-personal-email)
                       (mu4e-maildir-shortcuts . ( ("/icloud/INBOX" . ?i))))))))

   ((eq system-type 'gnu/linux)
    (setq send-mail-function 'sendmail-send-it
          sendmail-program "/usr/bin/msmtp"
          mail-specify-envelope-from t
          message-sendmail-envelope-from 'header
          mail-envelope-from 'header)
    (setq mu4e-contexts
          `(,(make-mu4e-context
              :name "wvwc-mail"
              :match-func (lambda (msg)
                            (when msg
                              (string-prefix-p "/gmail" (mu4e-message-field msg :maildir))))
              :vars '((mu4e-trash-folder . "/wvwc-mail/[Gmail]/Trash")
                      (mu4e-refile-folder . "/wvwc-mail/[Gmail]/Archive")
                      (user-mail-address . user-professional-email)
                      (mu4e-maildir-shortcuts . ( ("/wvwc-mail/INBOX" . ?i)))))
            ,(make-mu4e-context
              :name "math-gmail"
              :match-func (lambda (msg)
                            (when msg
                              (string-prefix-p "/gmail" (mu4e-message-field msg :maildir))))
              :vars '((mu4e-trash-folder . "/math-gmail/[Gmail]/Trash")
                      (mu4e-refile-folder . "/math-gmail/[Gmail]/Archive")
                      (user-mail-address . user-semi-professional-email)
                      (mu4e-maildir-shortcuts . ( ("/math-gmail/INBOX" . ?i))))))))))

;; Headers can be misaligned with columns in header view, so this code from
;; https://www.djcbsoftware.nl/code/mu/mu4e/Known-issues.html tries to fix it.
(add-hook 'mu4e-headers-mode-hook #'my-mu4e-headers-mode-hook)
(defun my-mu4e-headers-mode-hook ()
  ;; Account for the fringe and other spacing in the header line.
  (header-line-indent-mode 1)
  (push (propertize " " 'display '(space :align-to header-line-indent-width))
        header-line-format)
  ;; Ensure `text-scale-adjust' scales the header line with the headers themselves
  ;; by ensuring the `default' face is in the inheritance hierarchy.
  (face-remap-add-relative 'header-line
                           '(:inherit (mu4e-header-face default))))

;; This is taken from 8.2.1 in mu4e manual
(setq mu4e-headers-fields
      '((:human-date      .  10)
        (:flags           .  4)
        (:from-or-to      .  20)
        (:mailing-list    .  8)
        (:maildir         .  8)
        (:labels          .  8)
        (:thread-subject  .  nil)))

(setq mu4e-view-fields
      '(:from :date :to :cc :bcc :subject
              :flags  :maildir
              :message-id :labels))

;; The following is for integrating with org-msg.
(setq mail-user-agent 'mu4e-user-agent)
;; Config taken from org-msg github page.
(use-package org-msg
  :ensure t
  :after mu4e
  :custom
  (org-msg-options "html-postamble:nil H:5 num:nil ^:{} toc:nil author:nil email:nil \\n:t tex:dvisvgm")
  (org-msg-startup "hidestars indent inlineimages")
  (org-msg-greeting-fmt "\nHi%s,\n\n")
  ;; The code below demonstrates how to set recipient names, but for privacy
  ;; reasons I define these elsewhere.
  (org-msg-recipient-names user-mail-names)
  (org-msg-greeting-name-limit 3)
  (org-msg-default-alternatives '((new          . (text html))
                                  (reply-to-html     . (text html))
                                  (reply-to-text     . (text))))
  (org-msg-convert-citation t)
  (org-msg-signature "

#+begin_signature
--Jesse
#+end_signature")

  :bind (:map org-msg-edit-mode-map
              ("C-c C-g b" . message-goto-bcc)
              ("C-c C-g c" . message-goto-cc)
              ("C-c C-g f" . message-goto-from)
              ("C-c C-g m" . message-goto-body)
              ("C-c C-g s" . message-goto-subject)
              ("C-c C-g t" . message-goto-to))

  :hook ((message-mode . (lambda ()
                           (org-msg-mode 'toggle)))))

;; Disable fill-paragraph in org-msg to allow mu4e to format=flowed
;; each message.  See relevant documentation in mu4e block.
(use-package messages-are-flowing
  :ensure t
  :defer t
  :after org-msg
  :hook ((org-msg-edit-mode . turn-off-auto-fill)
         (org-msg-edit-mode . visual-line-mode)
         (org-msg-edit-mode . messages-are-flowing-use-and-mark-hard-newlines)))

(provide 'init-mail)
;;; init-mail.el ends here
