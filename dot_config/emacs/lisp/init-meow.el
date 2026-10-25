;;; init-meow.el --- Configuration for meow-mode -*- no-byte-compile: t; lexical-binding: t; -*-

;;; Commentary:

;; My customizations for Meow.

;;; Code:

(defun meow-setup ()
  "Define keybindings for Meow."
  (interactive)
  (setq meow-cheatsheet-layout meow-cheatsheet-layout-qwerty)
  (meow-motion-define-key
   '("j" . meow-next)
   '("k" . meow-prev)
   '("/" . consult-line)
   '("<escape>" . ignore))
  (meow-leader-define-key
   ;; SPC j/k will run the original command in MOTION state.
   '("j" . "H-j")
   '("k" . "H-k")
   '("/" . "H-/")
   ;; Use SPC (0-9) for digit arguments.
   '("1" . meow-digit-argument)
   '("2" . meow-digit-argument)
   '("3" . meow-digit-argument)
   '("4" . meow-digit-argument)
   '("5" . meow-digit-argument)
   '("6" . meow-digit-argument)
   '("7" . meow-digit-argument)
   '("8" . meow-digit-argument)
   '("9" . meow-digit-argument)
   '("0" . meow-digit-argument)
   '("/" . meow-keypad-describe-key)
   '("?" . meow-cheatsheet))
  (meow-normal-define-key
   '("0" . meow-expand-0)
   '("9" . meow-expand-9)
   '("8" . meow-expand-8)
   '("7" . meow-expand-7)
   '("6" . meow-expand-6)
   '("5" . meow-expand-5)
   '("4" . meow-expand-4)
   '("3" . meow-expand-3)
   '("2" . meow-expand-2)
   '("1" . meow-expand-1)
   '("-" . negative-argument)
   '(";" . meow-reverse)
   '("," . meow-inner-of-thing)
   '("." . meow-bounds-of-thing)
   '("[" . meow-beginning-of-thing)
   '("]" . meow-end-of-thing)
   '("a" . meow-append)
   '("A" . meow-open-below)
   '("b" . meow-back-word)
   '("B" . meow-back-symbol)
   '("c" . meow-change)
   '("d" . meow-delete)
   '("D" . meow-backward-delete)
   '("e" . meow-next-word)
   '("E" . meow-next-symbol)
   '("f" . flash-jump)
   '("F" . avy-goto-char-timer)
   '("g" . meow-cancel-selection)
   '("G" . meow-grab)
   '("h" . meow-left)
   '("H" . meow-left-expand)
   '("i" . meow-insert)
   '("I" . meow-open-above)
   '("j" . meow-next)
   '("J" . meow-next-expand)
   '("k" . meow-prev)
   '("K" . meow-prev-expand)
   '("l" . meow-right)
   '("L" . meow-right-expand)
   '("m" . meow-join)
   '("n" . meow-search)
   '("o" . meow-block)
   '("O" . meow-to-block)
   '("p" . meow-yank)
   '("q" . meow-quit)
   '("Q" . meow-goto-line)
   '("r" . meow-replace)
   '("R" . meow-swap-grab)
   '("s" . meow-kill)
   '("t" . meow-till)
   '("u" . undo-fu-only-undo)
   '("U" . undo-fu-only-redo)
   '("v" . meow-visit)
   '("V" . vundo)
   '("w" . meow-mark-word)
   '("W" . meow-mark-symbol)
   '("x" . meow-line)
   '("X" . meow-goto-line)
   '("y" . meow-save)
   '("Y" . meow-sync-grab)
   '("z" . meow-pop-selection)
   '("/" . consult-line)
   '("'" . repeat)
   '(")" . meow-forward-slurp)
   '("(" . meow-backward-slurp)
   '("}" . meow-forward-barf)
   '("{" . meow-backward-barf)
   '("<escape>" . ignore)
   '("<tab>" . kirigami-toggle-fold)
   '("<backtab>" . )))

;; Magit/angle config adapted from:
;; https://github.com/mclear-tools/dotemacs/blob/master/cpm-setup-meow.el
(use-package meow
  :ensure t
  :diminish meow-insert-mode
  :diminish meow-normal-mode
  :diminish meow-beacon-mode
  :diminish meow-motion-mode
  :custom
  (meow-expand-exclude-mode-list '(markdown-mode))
  (meow-expand-hint-remove-delay 2.0)
  :config
  (meow-thing-register 'angle '(regexp "<" ">") '(regexp "<" ">"))
  (add-to-list 'meow-char-thing-table '(?a . angle))
                                        ; LaTeX settings for meow. Taken from
                                        ; https://aatmunbaxi.netlify.app/comp/configuring_meow_friendly_latex/
  (meow-thing-register 'inline-math
                       '(pair ("\\(") ("\\)"))
                       '(pair ("\\(") ("\\)") ) )
  (add-to-list 'meow-char-thing-table '(?m . inline-math))
  ;; Default states for modes
  (add-to-list 'meow-mode-state-list '(Custom-mode . insert))
  (add-to-list 'meow-mode-state-list '(mu4e-main-mode . insert))
  (add-to-list 'meow-mode-state-list '(mu4e-view-mode . motion))
  (add-to-list 'meow-mode-state-list '(magit-status-mode . insert))
  (add-to-list 'meow-mode-state-list '(magit-log-mode . normal))
  (add-to-list 'meow-mode-state-list '(vundo-mode . insert))

  ;; Bring in keybindings from above.
  (meow-setup)
  (meow-global-mode 1))

(use-package meow-tree-sitter
  :ensure t
  :config
  (meow-tree-sitter-register-defaults))

(provide 'init-meow)
;;; init-meow.el ends here
