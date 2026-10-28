;;; init-lean.el --- Configuration for Lean4 in Emacs  -*- no-byte-compile: t; lexical-binding: t; -*-

;;; Commentary:

(use-package lean4-mode
  ;; :defer t
  :commands lean4-mode
  :vc (:url "https://github.com/leanprover-community/lean4-mode.git"
            :rev :last-release)
  ;; Or, if you prefer the bleeding edge version of Lean4-Mode:
  ;; :rev :newest
  )

(provide 'init-lean)
;;; init-lean.el ends here
