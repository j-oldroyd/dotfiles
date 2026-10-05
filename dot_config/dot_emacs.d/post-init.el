;;; post-init.el --- Very early initializations -*- ;;; no-byte-compile: t; lexical-binding: t; -*-

;;; Commentary:

;;; Code:

;; Native compilation enhances Emacs performance by converting Elisp code into
;; native machine code, resulting in faster execution and improved
;; responsiveness.
;;
;; Ensure adding the following compile-angel code at the very beginning
;; of your `~/.emacs.d/post-init.el` file, before all other packages.
(use-package compile-angel
  :demand t
  :config
  ;; Set `compile-angel-verbose' to nil to disable compile-angel messages.
  ;; (When set to nil, compile-angel won't show which file is being compiled.)
  (setq compile-angel-verbose t)

  ;; The following directive prevents compile-angel from compiling your init
  ;; files. If you choose to remove this push to `compile-angel-excluded-files'
  ;; and compile your pre/post-init files, ensure you understand the
  ;; implications and thoroughly test your code. For example, if you're using
  ;; the `use-package' macro, you'll need to explicitly add:
  ;; (eval-when-compile (require 'use-package))
  ;; at the top of your init file.
  (push "/init.el" compile-angel-excluded-files)
  (push "/early-init.el" compile-angel-excluded-files)
  (push "/pre-init.el" compile-angel-excluded-files)
  (push "/post-init.el" compile-angel-excluded-files)
  (push "/pre-early-init.el" compile-angel-excluded-files)
  (push "/post-early-init.el" compile-angel-excluded-files)

  ;; A local mode that compiles .el files whenever the user saves them.
  ;; (add-hook 'emacs-lisp-mode-hook #'compile-angel-on-save-local-mode)

  ;; A global mode that compiles .el files prior to loading them via `load' or
  ;; `require'. Additionally, it compiles all packages that were loaded before
  ;; the mode `compile-angel-on-load-mode' was activated.
  (compile-angel-on-load-mode 1))

;; Auto-revert in Emacs is a feature that automatically updates the
;; contents of a buffer to reflect changes made to the underlying file
;; on disk.
(use-package autorevert
  :ensure nil
  :init
  ;; (setq auto-revert-verbose t)
  (setq auto-revert-interval 3)
  (setq auto-revert-remote-files nil)
  (setq auto-revert-use-notify t)
  (setq auto-revert-avoid-polling nil)
  (global-auto-revert-mode 1))

;; Recentf is an Emacs package that maintains a list of recently
;; accessed files, making it easier to reopen files you have worked on
;; recently.
(use-package recentf
  :ensure nil
  :init
  (setq recentf-auto-cleanup (if (daemonp) 300 'never))
  (setq recentf-exclude
        (list "\\.tar$" "\\.tbz2$" "\\.tbz$" "\\.tgz$" "\\.bz2$"
              "\\.bz$" "\\.gz$" "\\.gzip$" "\\.xz$" "\\.zip$"
              "\\.7z$" "\\.rar$"
              "COMMIT_EDITMSG\\'"
              "\\.\\(?:gz\\|gif\\|svg\\|png\\|jpe?g\\|bmp\\|xpm\\)$"
              "-autoloads\\.el$" "autoload\\.el$"))
  ;; Enable `recentf-mode'
  (recentf-mode 1)

  :config
  ;; A cleanup depth of -90 ensures that `recentf-cleanup' runs before
  ;; `recentf-save-list', allowing stale entries to be removed before the list
  ;; is saved by `recentf-save-list', which is automatically added to
  ;; `kill-emacs-hook' by `recentf-mode'.
  (add-hook 'kill-emacs-hook #'recentf-cleanup -90))

;; savehist is an Emacs feature that preserves the minibuffer history between
;; sessions. It saves the history of inputs in the minibuffer, such as commands,
;; search strings, and other prompts, to a file. This allows users to retain
;; their minibuffer history across Emacs restarts.
(use-package savehist
  :ensure nil
  :init
  (setq history-length 300)
  (setq savehist-autosave-interval 600)
  (savehist-mode 1))

;; save-place-mode enables Emacs to remember the last location within a file
;; upon reopening. This feature is particularly beneficial for resuming work at
;; the precise point where you previously left off.
(use-package saveplace
  :ensure nil
  :init
  (setq save-place-limit 400)
  (save-place-mode 1))

;; Enable `auto-save-mode' to prevent data loss. Use `recover-file' or
;; `recover-session' to restore unsaved changes.
(setq auto-save-default t)

;; Trigger an auto-save after 300 keystrokes
(setq auto-save-interval 300)

;; Trigger an auto-save 30 seconds of idle time.
(setq auto-save-timeout 30)

;; Corfu enhances in-buffer completion by displaying a compact popup with
;; current candidates, positioned either below or above the point. Candidates
;; can be selected by navigating up or down.
(use-package corfu
  :init
  (setq text-mode-ispell-word-completion nil)
  ;; Hide commands in M-x which do not apply to the current mode.
  (setq read-extended-command-predicate #'command-completion-default-include-p)
  ;; Disable Ispell completion function. As an alternative try `cape-dict'.
  (setq tab-always-indent 'complete)

  (global-corfu-mode 1))

;; Cape, or Completion At Point Extensions, extends the capabilities of
;; in-buffer completion. It integrates with Corfu or the default completion UI,
;; by providing additional backends through completion-at-point-functions.
(use-package cape
  :commands (cape-dabbrev cape-file cape-elisp-block)
  :bind ("C-c p" . cape-prefix-map)
  :init
  ;; Add to the global default value of `completion-at-point-functions' which is
  ;; used by `completion-at-point'.
  (add-hook 'completion-at-point-functions #'cape-dabbrev)
  (add-hook 'completion-at-point-functions #'cape-file)
  (add-hook 'completion-at-point-functions #'cape-elisp-block))

;; Vertico provides a vertical completion interface, making it easier to
;; navigate and select from completion candidates (e.g., when `M-x` is pressed).
(use-package vertico
  :init
  ;; (setq vertico-scroll-margin 0) ;; Different scroll margin
  ;; (setq vertico-count 20) ;; Show more candidates
  ;; (setq vertico-resize t) ;; Grow and shrink the Vertico minibuffer
  ;; (setq vertico-cycle t) ;; Enable cycling for `vertico-next/previous'
  (vertico-mode 1))

;; Vertico leverages Orderless' flexible matching capabilities, allowing users
;; to input multiple patterns separated by spaces, which Orderless then
;; matches in any order against the candidates.
(use-package orderless
  :init
  (setq completion-styles '(orderless basic))
  (setq completion-category-overrides '((file (styles partial-completion))))
  ;; Emacs 31: partial-completion behaves like substring
  (setq completion-pcm-leading-wildcard t))

;; Marginalia allows Embark to offer you preconfigured actions in more contexts.
;; In addition to that, Marginalia also enhances Vertico by adding rich
;; annotations to the completion candidates displayed in Vertico's interface.
(use-package marginalia
  ;; Bind `marginalia-cycle' locally in the minibuffer.  To make the binding
  ;; available in the *Completions* buffer, add it to the
  ;; `completion-list-mode-map'.
  :bind (:map minibuffer-local-map
         ("M-A" . marginalia-cycle))

  ;; The :init section is always executed.
  :init

  ;; Marginalia must be activated in the :init section of use-package such that
  ;; the mode gets enabled right away. Note that this forces loading the
  ;; package.
  (marginalia-mode 1))

;; Embark integrates with Consult and Vertico to provide context-sensitive
;; actions and quick access to commands based on the current selection, further
;; improving user efficiency and workflow within Emacs. Together, they create a
;; cohesive environment for managing completions and interactions.
(use-package embark
  :bind
  (("C-." . embark-act)         ;; pick some comfortable binding
   ("C-;" . embark-dwim)        ;; good alternative: M-.
   ("C-h B" . embark-bindings)) ;; alternative for `describe-bindings'

  :init

  ;; Optionally replace the key help with a completing-read interface
  (setq prefix-help-command #'embark-prefix-help-command)

  ;; Show the Embark target at point via Eldoc. You may adjust the
  ;; Eldoc strategy, if you want to see the documentation from
  ;; multiple providers. Beware that using this can be a little
  ;; jarring since the message shown in the minibuffer can be more
  ;; than one line, causing the modeline to move up and down:

  ;; (add-hook 'eldoc-documentation-functions #'embark-eldoc-first-target)
  ;; (setq eldoc-documentation-strategy #'eldoc-documentation-compose-eagerly)

  ;; Add Embark to the mouse context menu. Also enable `context-menu-mode'.
  ;; (context-menu-mode 1)
  ;; (add-hook 'context-menu-functions #'embark-context-menu 100)

  :config
  ;; Hide the mode line of the Embark live/completions buffers
  (add-to-list 'display-buffer-alist
               '("\\`\\*Embark Collect \\(Live\\|Completions\\)\\*"
                 nil
                 (window-parameters (mode-line-format . none)))))

(use-package embark-consult)

;; Consult offers a suite of commands for efficient searching, previewing, and
;; interacting with buffers, file contents, and more, improving various tasks.

(use-package consult
  ;; Replace bindings. Lazily loaded by `use-package'.
  :bind (;; C-c bindings in `mode-specific-map'
         ("C-c M-x" . consult-mode-command)
         ("C-c h" . consult-history)
         ("C-c k" . consult-kmacro)
         ("C-c m" . consult-man)
         ("C-c i" . consult-info)
         ([remap Info-search] . consult-info)
         ;; C-x bindings in `ctl-x-map'
         ("C-x M-:" . consult-complex-command)     ;; orig. repeat-complex-command
         ("C-x b" . consult-buffer)                ;; orig. switch-to-buffer
         ("C-x 4 b" . consult-buffer-other-window) ;; orig. switch-to-buffer-other-window
         ("C-x 5 b" . consult-buffer-other-frame)  ;; orig. switch-to-buffer-other-frame
         ("C-x t b" . consult-buffer-other-tab)    ;; orig. switch-to-buffer-other-tab
         ("C-x r b" . consult-bookmark)            ;; orig. bookmark-jump
         ("C-x p b" . consult-project-buffer)      ;; orig. project-switch-to-buffer
         ;; Custom M-# bindings for fast register access
         ("M-#" . consult-register-load)
         ("M-'" . consult-register-store)          ;; orig. abbrev-prefix-mark (unrelated)
         ("C-M-#" . consult-register)
         ;; Other custom bindings
         ("M-y" . consult-yank-pop)                ;; orig. yank-pop
         ;; M-g bindings in `goto-map'
         ("M-g e" . consult-compile-error)
         ("M-g r" . consult-grep-match)
         ("M-g f" . consult-flymake)               ;; Alternative: consult-flycheck
         ("M-g g" . consult-goto-line)             ;; orig. goto-line
         ("M-g M-g" . consult-goto-line)           ;; orig. goto-line
         ("M-g o" . consult-outline)               ;; Alternative: consult-org-heading
         ("M-g m" . consult-mark)
         ("M-g k" . consult-global-mark)
         ("M-g i" . consult-imenu)
         ("M-g I" . consult-imenu-multi)
         ;; M-s bindings in `search-map'
         ("M-s d" . consult-find)                  ;; Alternative: consult-fd
         ("M-s c" . consult-locate)
         ("M-s g" . consult-grep)
         ("M-s G" . consult-git-grep)
         ("M-s r" . consult-ripgrep)
         ("M-s l" . consult-line)
         ("M-s L" . consult-line-multi)
         ("M-s k" . consult-keep-lines)
         ("M-s u" . consult-focus-lines)
         ;; Isearch integration
         ("M-s e" . consult-isearch-history)
         :map isearch-mode-map
         ("M-e" . consult-isearch-history)         ;; orig. isearch-edit-string
         ("M-s e" . consult-isearch-history)       ;; orig. isearch-edit-string
         ("M-s l" . consult-line)                  ;; needed by consult-line to detect isearch
         ("M-s L" . consult-line-multi)            ;; needed by consult-line to detect isearch
         ;; Minibuffer history
         :map minibuffer-local-map
         ("M-s" . consult-history)                 ;; orig. next-matching-history-element
         ("M-r" . consult-history))                ;; orig. previous-matching-history-element

  ;; The :init configuration is always executed (Not lazy)
  :init

  ;; Tweak the register preview for `consult-register-load',
  ;; `consult-register-store' and the built-in commands.  This improves the
  ;; register formatting, adds thin separator lines, register sorting and hides
  ;; the window mode line.
  (advice-add #'register-preview :override #'consult-register-window)
  (setq register-preview-delay 0.5)

  ;; Use Consult to select xref locations with preview
  (setq xref-show-xrefs-function #'consult-xref
        xref-show-definitions-function #'consult-xref)

  ;; Configure other variables and modes in the :config section,
  ;; after lazily loading the package.
  :config

  ;; Optionally configure preview. The default value
  ;; is 'any, such that any key triggers the preview.
  ;; (setq consult-preview-key 'any)
  ;; (setq consult-preview-key "M-.")
  ;; (setq consult-preview-key '("S-<down>" "S-<up>"))
  ;; For some commands and buffer sources it is useful to configure the
  ;; :preview-key on a per-command basis using the `consult-customize' macro.
  (consult-customize
   consult-theme :preview-key '(:debounce 0.2 any)
   consult-ripgrep consult-git-grep consult-grep consult-man
   consult-bookmark consult-recent-file consult-xref
   consult-source-bookmark consult-source-file-register
   consult-source-recent-file consult-source-project-recent-file
   ;; :preview-key "M-."
   :preview-key '(:debounce 0.4 any))

  ;; Optionally configure the narrowing key.
  ;; Both < and C-+ work reasonably well.
  (setq consult-narrow-key "<") ;; "C-+"

  ;; Optionally make narrowing help available in the minibuffer.
  ;; You may want to use `embark-prefix-help-command' or which-key instead.
  ;; (keymap-set consult-narrow-map (concat consult-narrow-key " ?") #'consult-narrow-help)
  )

;; The undo-fu package is a lightweight wrapper around Emacs' built-in undo
;; system, providing more convenient undo/redo functionality.
(use-package undo-fu
  :commands (undo-fu-only-undo
             undo-fu-only-redo
             undo-fu-only-redo-all
             undo-fu-disable-checkpoint)
  :init
  (global-unset-key (kbd "C-z"))
  (global-set-key (kbd "C-z") 'undo-fu-only-undo)
  (global-set-key (kbd "C-S-z") 'undo-fu-only-redo))

;; The undo-fu-session package complements undo-fu by enabling the saving
;; and restoration of undo history across Emacs sessions, even after restarting.
(use-package undo-fu-session
  :init
  (undo-fu-session-global-mode 1))

(let ((inhibit-redisplay t))
  ;; Disable all active themes
  (mapc #'disable-theme custom-enabled-themes)
  ;; Load the built-in theme
  (load-theme 'modus-operandi t))

;; Give Emacs tab-bar a style similar to Vim's
(use-package vim-tab-bar
  :init
  (vim-tab-bar-mode 1))

;; The easysession Emacs package is a session manager for Emacs that
;; can persist and restore file editing buffers, indirect
;; buffers/clones, Dired buffers, windows/splits, the built-in tab-bar
;; (including tabs, their buffers, and windows), and Emacs frames. It
;; offers a convenient and effortless way to manage Emacs editing
;; sessions and utilizes built-in Emacs functions to persist and
;; restore frames.
(use-package easysession
  ;; ':demand t' ensures the package is loaded immediately upon startup
  :demand t

  :config
  ;; Key mappings
  (global-set-key (kbd "C-c sl") #'easysession-switch-to) ; Load session
  (global-set-key (kbd "C-c ss") #'easysession-save) ; Save session
  (global-set-key (kbd "C-c sL") #'easysession-switch-to-and-restore-geometry)
  (global-set-key (kbd "C-c sr") #'easysession-rename)
  (global-set-key (kbd "C-c sR") #'easysession-reset)
  (global-set-key (kbd "C-c su") #'easysession-unload)
  (global-set-key (kbd "C-c sd") #'easysession-delete)

  ;; Save every 10 minutes
  (setq easysession-save-interval (* 10 60))

  ;; Save the current session when using `easysession-switch-to'
  (setq easysession-switch-to-save-session t)

  ;; Do not exclude the current session when switching sessions
  (setq easysession-switch-to-exclude-current nil)

  ;; Display the active session name in the mode-line lighter.
  ;; (setq easysession-save-mode-lighter-show-session-name t)

  ;; Optionally, the session name can be shown in the modeline info area:
  ;; (setq easysession-mode-line-misc-info t)
  ;; non-nil: Make `easysession-setup' load the session automatically.
  ;; (nil: session is not loaded automatically; the user can load it manually.)
  (setq easysession-setup-load-session t)

  ;; The `easysession-setup' function adds hooks:
  ;; - To enable automatic session loading during `emacs-startup-hook', or
  ;;   `server-after-make-frame-hook' when running in daemon mode.
  ;; - To save the session at regular intervals, and when Emacs exits.
  (easysession-setup))

(use-package kirigami
  :commands (kirigami-open-fold
             kirigami-open-fold-rec
             kirigami-close-fold
             kirigami-toggle-fold
             kirigami-open-folds
             kirigami-close-folds-except-current
             kirigami-close-folds)

  :bind
  (("C-c z o" . kirigami-open-fold)      ; Open fold at point
   ("C-c z O" . kirigami-open-fold-rec)  ; Open fold recursively
   ("C-c z r" . kirigami-open-folds)     ; Open all folds
   ("C-c z c" . kirigami-close-fold)     ; Close fold at point
   ("C-c z m" . kirigami-close-folds)    ; Close all folds
   ("C-c z a" . kirigami-toggle-fold))   ; Toggle fold at point

  :init
  (kirigami-global-mode 1))

;; The built-in outline-minor-mode provides structured code folding in
;; modes such as Emacs Lisp and Python, allowing users to collapse and
;; expand sections based on headings or indentation levels. This
;; feature enhances navigation and improves the management of large
;; files with hierarchical structures.
(use-package outline
  :ensure nil
  :commands outline-minor-mode
  :hook
  (;; Use " ▼" instead of the default ellipsis "..." for folded text to make
   ;; folds more visually distinctive and readable.
   (outline-minor-mode
    .
    (lambda()
      (let* ((display-table (or buffer-display-table (make-display-table)))
             (face-offset (* (face-id 'shadow) (ash 1 22)))
             (value (vconcat (mapcar (lambda (c) (+ face-offset c)) " ▼"))))
        (set-display-table-slot display-table 'selective-display value)
        (setq buffer-display-table display-table))))))

;; Enable the mode
(add-hook 'emacs-lisp-mode-hook #'outline-minor-mode)
(add-hook 'lisp-mode-hook #'outline-minor-mode)
(add-hook 'conf-mode-hook #'outline-minor-mode)
(add-hook 'markdown-mode-hook #'outline-minor-mode)
(add-hook 'diff-mode-hook #'outline-minor-mode)

;; The outline-indent Emacs package provides a minor mode that enables code
;; folding based on indentation levels.
;; In addition to code folding, outline-indent allows:
;; - Moving indented blocks up and down
;; - Indenting/unindenting to adjust indentation levels
;; - Inserting a new line with the same indentation level as the current line
;; - Move backward/forward to the indentation level of the current line
;; - and other features.
(use-package outline-indent
  :commands outline-indent-minor-mode
  :init
  (setq outline-indent-ellipsis " ▼"))

;; Python
(add-hook 'python-mode-hook #'outline-indent-minor-mode)
(add-hook 'python-ts-mode-hook #'outline-indent-minor-mode)

;; Yaml
(add-hook 'yaml-mode-hook #'outline-indent-minor-mode)
(add-hook 'yaml-ts-mode-hook #'outline-indent-minor-mode)

;; Haskell
(add-hook 'haskell-mode-hook #'outline-indent-minor-mode)

;; Intelligent code folding by using the structural understanding of the
;; built-in tree-sitter parser. Unlike traditional folding methods that rely on
;; regular expressions or indentation, treesit-fold uses the actual syntax tree
;; of the code to accurately identify foldable regions such as functions,
;; classes, comments, and documentation strings. This allows for faster and more
;; precise folding behavior that respects the grammar of the programming
;; language, ensuring that fold boundaries are always syntactically correct even
;; in complex or nested code structures.
(use-package treesit-fold
  :commands (treesit-fold-close
             treesit-fold-close-all
             treesit-fold-open
             treesit-fold-toggle
             treesit-fold-open-all
             treesit-fold-mode
             global-treesit-fold-mode
             treesit-fold-open-recursively
             treesit-fold-line-comment-mode)

  :init
  (setq treesit-fold-line-count-show t)
  (setq treesit-fold-line-count-format " ▼")

  :config
  (set-face-attribute 'treesit-fold-replacement-face nil
                      :foreground "#808080"
                      :box nil
                      :weight 'bold))

;; A few examples
(add-hook 'c-ts-mode-hook #'treesit-fold-mode)
(add-hook 'c++-ts-mode-hook #'treesit-fold-mode)
(add-hook 'php-ts-mode-hook #'treesit-fold-mode)
(add-hook 'css-ts-mode-hook #'treesit-fold-mode)
(add-hook 'html-ts-mode-hook #'treesit-fold-mode)
(add-hook 'bash-ts-mode-hook #'treesit-fold-mode)

;; Apheleia is an Emacs package designed to run code formatters (e.g., Shfmt,
;; Black and Prettier) asynchronously without disrupting the cursor position.
(use-package apheleia
  :commands (apheleia-mode
             apheleia-global-mode)
  :hook ((prog-mode . apheleia-mode)))


(use-package dumb-jump
  :commands dumb-jump-xref-activate
  :init
  ;; Register `dumb-jump' as an xref backend so it integrates with
  ;; `xref-find-definitions'. A priority of 80 ensures it is used only when no
  ;; more specific backend is available.
  (with-eval-after-load 'xref
    (add-hook 'xref-backend-functions #'dumb-jump-xref-activate 80))

  (setq dumb-jump-aggressive nil)
  ;; (setq dumb-jump-quiet t)

  ;; Number of seconds a rg/grep/find command can take before being warned to
  ;; use ag and config.
  (setq dumb-jump-max-find-time 3)

  ;; Use `completing-read' so that selection of jump targets integrates with the
  ;; active completion framework (e.g., Vertico, Ivy, Helm, Icomplete),
  ;; providing a consistent minibuffer-based interface whenever multiple
  ;; definitions are found.
  (setq dumb-jump-selector 'completing-read)

  :config
  ;; If ripgrep is available, force `dumb-jump' to use it because it is
  ;; significantly faster and more accurate than the default searchers (grep,
  ;; ag, etc.).
  (when (executable-find "rg")
    (setq dumb-jump-force-searcher 'rg)
    (setq dumb-jump-prefer-searcher 'rg)))

;; The official collection of snippets for yasnippet.
(use-package yasnippet-snippets)

;; YASnippet is a template system designed that enhances text editing
;; by enabling users to define and use snippets. When a user types a
;; short abbreviation, YASnippet automatically expands it into a full
;; template, which can include placeholders, fields, and dynamic
;; content.
(use-package yasnippet
  :after yasnippet-snippets
  :init
  (setq yas-also-auto-indent-first-line t)  ; Indent first line of snippet
  (setq yas-also-indent-empty-lines t)
  (setq yas-snippet-revival nil)  ; Setting this to t causes issues with undo
  (setq yas-wrap-around-region nil) ; Do not wrap region when expanding snippets
  (setq yas-indent-line 'fixed) ; Do not auto-indent snippet content
  ;; (setq yas-triggers-in-field nil)  ; Disable nested snippet expansion
  ;; (setq yas-prompt-functions '(yas-no-prompt))  ; No prompt for snippet choices

  ;; Suppress verbose messages
  (setq yas-verbosity 0)

  (yas-global-mode 1))

;; The stripspace Emacs package provides stripspace-local-mode, a
;; minor mode that automatically removes trailing whitespace and blank
;; lines at the end of the buffer when saving.
(use-package stripspace
  :commands stripspace-local-mode

  ;; Enable for prog-mode-hook, text-mode-hook, conf-mode-hook
  :hook ((prog-mode . stripspace-local-mode)
         (text-mode . stripspace-local-mode)
         (conf-mode . stripspace-local-mode))

  :init
  ;; The `stripspace-only-if-initially-clean' option: - nil to always
  ;; delete trailing whitespace.  - Non-nil to only delete whitespace
  ;; when the buffer is clean initially.  (The initial cleanliness
  ;; check is performed when `stripspace-local-mode' is enabled.)
  (setq stripspace-only-if-initially-clean nil)

  ;; Enabling `stripspace-restore-column' preserves the cursor's
  ;; column position even after stripping spaces. This is useful in
  ;; scenarios where you add extra spaces and then save the
  ;; file. Although the spaces are removed in the saved file, the
  ;; cursor remains in the same position, ensuring a consistent
  ;; editing experience without affecting cursor placement.
  (setq stripspace-restore-column t))

(use-package diff-hl
  :commands (diff-hl-mode
             global-diff-hl-mode)
  :hook (prog-mode . diff-hl-mode)
  :init
  (setq diff-hl-flydiff-delay 0.4)  ; Faster
  (setq diff-hl-show-staged-changes nil)  ; Realtime feedback
  (setq diff-hl-update-async t)  ; Do not block Emacs
  (setq diff-hl-global-modes '(not pdf-view-mode image-mode)))

;; Org mode is a major mode designed for organizing notes, planning, task
;; management, and authoring documents using plain text with a simple and
;; expressive markup syntax. It supports hierarchical outlines, TODO lists,
;; scheduling, deadlines, time tracking, and exporting to multiple formats
;; including HTML, LaTeX, PDF, and Markdown.
(use-package org
  :commands (org-mode org-version)
  :mode
  ("\\.org\\'" . org-mode)
  :init
  (setq org-hide-leading-stars t)
  (setq org-startup-indented t)
  (setq org-adapt-indentation nil)
  (setq org-edit-src-content-indentation 0)
  ;; (setq org-fontify-done-headline t)
  ;; (setq org-fontify-todo-headline t)
  ;; (setq org-fontify-whole-heading-line t)
  ;; (setq org-fontify-quote-and-verse-blocks t)
  (setq org-startup-truncated t))

;; Set up the Language Server Protocol (LSP) servers using Eglot.
(use-package eglot
  :ensure nil
  :commands (eglot-ensure
             eglot-rename
             eglot-format-buffer))

;; Configure Eglot to enable or disable certain options for the pylsp
;; server in Python development. (Note that a third-party tool,
;; https://github.com/python-lsp/python-lsp-server, must be
;; installed),
(add-hook 'python-mode-hook #'eglot-ensure)
(add-hook 'python-ts-mode-hook #'eglot-ensure)
(setq-default eglot-workspace-configuration
              `(:pylsp (:plugins
                        (;; Fix imports and syntax using `eglot-format-buffer`
                         :isort (:enabled t)
                         :autopep8 (:enabled t)

                         ;; Syntax checkers (works with Flymake)
                         :pylint (:enabled t)
                         :pycodestyle (:enabled t)
                         :flake8 (:enabled t)
                         :pyflakes (:enabled t)
                         :pydocstyle (:enabled t)
                         :mccabe (:enabled t)

                         :yapf (:enabled :json-false)
                         :rope_autoimport (:enabled :json-false)))))

(use-package buffer-terminator
  :init
  ;; Enable/Disable verbose mode to log buffer cleanup events
  (setq buffer-terminator-verbose nil)

  ;; Set the inactivity timeout (in seconds) after which buffers are
  ;; considered inactive (default is 30 minutes):
  (setq buffer-terminator-inactivity-timeout (* 30 60)) ; 30 minutes

  ;; Define how frequently the cleanup process should run (default is
  ;; every 10 minutes):
  (setq buffer-terminator-interval (* 10 60)) ; 10 minutes

  (buffer-terminator-mode 1))

;; A file and project explorer for Emacs that displays a structured tree
;; layout, similar to file browsers in modern IDEs. It functions as a sidebar
;; in the left window, providing a persistent view of files, projects, and
;; other elements.
(use-package treemacs
  :commands (treemacs
             treemacs-select-window
             treemacs-delete-other-windows
             treemacs-select-directory
             treemacs-bookmark
             treemacs-find-file
             treemacs-find-tag)

  :bind
  (:map global-map
        ("M-0"       . treemacs-select-window)
        ("C-x t 1"   . treemacs-delete-other-windows)
        ("C-x t t"   . treemacs)
        ("C-x t d"   . treemacs-select-directory)
        ("C-x t B"   . treemacs-bookmark)
        ("C-x t C-t" . treemacs-find-file)
        ("C-x t M-t" . treemacs-find-tag))

  :init
  (with-eval-after-load 'winum
    (define-key winum-keymap (kbd "M-0") #'treemacs-select-window))

  :config
  (setq treemacs-collapse-dirs                   (if treemacs-python-executable 3 0)
        treemacs-deferred-git-apply-delay        0.5
        treemacs-directory-name-transformer      #'identity
        treemacs-display-in-side-window          t
        treemacs-eldoc-display                   'simple
        treemacs-file-event-delay                2000
        treemacs-file-extension-regex            treemacs-last-period-regex-value
        treemacs-file-follow-delay               0.2
        treemacs-file-name-transformer           #'identity
        treemacs-follow-after-init               t
        treemacs-expand-after-init               t
        treemacs-find-workspace-method           'find-for-file-or-pick-first
        treemacs-git-command-pipe                ""
        treemacs-goto-tag-strategy               'refetch-index
        treemacs-header-scroll-indicators        '(nil . "^^^^^^")
        treemacs-hide-dot-git-directory          t
        treemacs-indentation                     2
        treemacs-indentation-string              " "
        treemacs-is-never-other-window           nil
        treemacs-max-git-entries                 5000
        treemacs-missing-project-action          'ask
        treemacs-move-files-by-mouse-dragging    t
        treemacs-move-forward-on-expand          nil
        treemacs-no-png-images                   nil
        treemacs-no-delete-other-windows         t
        treemacs-project-follow-cleanup          nil
        treemacs-persist-file                    (expand-file-name ".cache/treemacs-persist" user-emacs-directory)
        treemacs-position                        'left
        treemacs-read-string-input               'from-child-frame
        treemacs-recenter-distance               0.1
        treemacs-recenter-after-file-follow      nil
        treemacs-recenter-after-tag-follow       nil
        treemacs-recenter-after-project-jump     'always
        treemacs-recenter-after-project-expand   'on-distance
        treemacs-litter-directories              '("/node_modules" "/.venv" "/.cask")
        treemacs-project-follow-into-home        nil
        treemacs-show-cursor                     nil
        treemacs-show-hidden-files               t
        treemacs-silent-filewatch                nil
        treemacs-silent-refresh                  nil
        treemacs-sorting                         'alphabetic-asc
        treemacs-select-when-already-in-treemacs 'move-back
        treemacs-space-between-root-nodes        t
        treemacs-tag-follow-cleanup              t
        treemacs-tag-follow-delay                1.5
        treemacs-text-scale                      nil
        treemacs-user-mode-line-format           nil
        treemacs-user-header-line-format         nil
        treemacs-wide-toggle-width               70
        treemacs-width                           35
        treemacs-width-increment                 1
        treemacs-width-is-initially-locked       t
        treemacs-workspace-switch-cleanup        nil)

  ;; The default width and height of the icons is 22 pixels. If you are
  ;; using a Hi-DPI display, uncomment this to double the icon size.
  ;; (treemacs-resize-icons 44)

  (treemacs-follow-mode t)
  (treemacs-filewatch-mode t)
  (treemacs-fringe-indicator-mode 'always)

  ;;(when treemacs-python-executable
  ;;  (treemacs-git-commit-diff-mode t))

  (pcase (cons (not (null (executable-find "git")))
               (not (null treemacs-python-executable)))
    (`(t . t)
     (treemacs-git-mode 'deferred))
    (`(t . _)
     (treemacs-git-mode 'simple)))

  (treemacs-hide-gitignored-files-mode nil))

 (use-package treemacs-icons-dired
   :hook (dired-mode . treemacs-icons-dired-enable-once))

 (use-package treemacs-tab-bar  ; treemacs-tab-bar if you use tab-bar-mode
   :after (treemacs)
   :config (treemacs-set-scope-type 'Tabs))

;; (treemacs-start-on-boot)

;; Helpful is an alternative to the built-in Emacs help that provides
;; much more contextual information.
(use-package helpful
  :commands (helpful-callable
             helpful-variable
             helpful-key
             helpful-command
             helpful-at-point
             helpful-function)
  :bind
  ([remap describe-command] . helpful-command)
  ([remap describe-function] . helpful-callable)
  ([remap describe-key] . helpful-key)
  ([remap describe-symbol] . helpful-symbol)
  ([remap describe-variable] . helpful-variable)
  :init
  (setq helpful-max-buffers 7))

(use-package bufferfile
  :commands (bufferfile-copy
             bufferfile-rename
             bufferfile-delete)
  :init
  ;; If non-nil, display messages during file renaming operations
  (setq bufferfile-verbose nil)

  ;; If non-nil, enable using version control (VC) when available
  (setq bufferfile-use-vc nil)

  ;; Specifies the action taken after deleting a file and killing its
  ;; buffer.
  (setq bufferfile-delete-switch-to 'parent-directory))

;; Enables automatic indentation of code while typing
(use-package aggressive-indent
  :commands aggressive-indent-mode
  :hook
  (emacs-lisp-mode . aggressive-indent-mode))

;; Highlights function and variable definitions in Emacs Lisp mode
(use-package highlight-defined
  :commands highlight-defined-mode
  :hook
  (emacs-lisp-mode . highlight-defined-mode))

;; Prevent parenthesis imbalance
(use-package paredit
  :commands paredit-mode
  :hook
  (emacs-lisp-mode . paredit-mode)
  :config
  (define-key paredit-mode-map (kbd "RET") nil))

;; For paredit+Evil mode users: enhances paredit with Evil mode compatibility
;; --------------------------------------------------------------------------
;; (use-package enhanced-evil-paredit
;;   :commands enhanced-evil-paredit-mode
;;   :hook
;;   (paredit-mode . enhanced-evil-paredit-mode))

;; Displays visible indicators for page breaks
(use-package page-break-lines
  :commands (page-break-lines-mode
             global-page-break-lines-mode)
  :hook
  (emacs-lisp-mode . page-break-lines-mode))

;; Provides functions to find references to functions, macros,
;; variables, special forms, and symbols in Emacs Lisp
(use-package elisp-refs
  :commands (elisp-refs-function
             elisp-refs-macro
             elisp-refs-variable
             elisp-refs-special
             elisp-refs-symbol))

;; Configure the `tab-bar-show` variable to 1 to display the tab bar
;; exclusively when multiple tabs are open:
(setopt tab-bar-show 1)

(use-package quick-sdcv
  :commands (quick-sdcv-search-at-point
             quick-sdcv-search-input)
  :init
  ;; When non-nil, a distinct buffer is created for each word
  ;; searched.
  (setq quick-sdcv-unique-buffers t)

  ;; Change the prefix character used before dictionary names,
  ;; replacing the default `-->`:
  (setq quick-sdcv-dictionary-prefix-symbol "►")

  ;; Change the quick-sdcv dictionaries ellipsis from … to " ▼" (In
  ;; quick-sdcv buffers, `outline-minor-mode' is enabled by default,
  ;; which allows sections corresponding to individual dictionaries to
  ;; be folded. The ellipsis … indicates a folded section, making it
  ;; easy to collapse all dictionaries and expand only those of
  ;; interest.)
  (setq quick-sdcv-ellipsis " ▼")

  ;; Automatically fold all dictionary entries when performing a search.
  ;; You can then unfold the dictionaries you want to read.
  (setq quick-sdcv-fold-on-search t))

;; The Emacs server allows external programs such as `emacsclient' to
;; connect to a single running instance of Emacs. This makes it
;; possible to open files in the existing session rather than starting
;; a new Emacs process each time.
;;
;; Once the server is running, the `emacsclient' command can be used
;; in the terminal to open files in the active Emacs session. For
;; example, running the following command opens the file in the
;; existing Emacs frame without blocking the terminal process.
;; emacsclient -n filename.txt

(use-package server
  :ensure nil
  :if (not (daemonp))
  :preface
  (defun my-server-start ()
    "Start the Emacs server if no server process is currently active."
    (unless (server-running-p)
      (server-start)))
  :init
  ;; Defer starting the server until after Emacs has finished
  ;; initializing
  (add-hook 'emacs-startup-hook #'my-server-start))

;;; (provide post-init.el)
;;; post-init.el ends here
