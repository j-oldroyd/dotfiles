;;; init-lean.el --- Configuration for Lean4 in Emacs  -*- no-byte-compile: t; lexical-binding: t; -*-

;;; Commentary:

(use-package lean4-mode
  :ensure (:host github
                 :repo "leanprover-community/lean4-mode"
                 :files ("*.el" "data"))
  :commands lean4-mode)

(provide 'init-lean)
;;; init-lean.el ends here
