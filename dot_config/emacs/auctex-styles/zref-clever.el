;;; zref-clever.el --- AUCTeX style for zref-clever  -*- lexical-binding: t; -*-
(TeX-add-style-hook
 "zref-clever"
 (lambda ()
   (TeX-add-symbols
    '("zcref" [ "Options" ] TeX-arg-ref)
    '("zcpageref" [ "Options" ] TeX-arg-ref)
    '("zcsetup" t)
    '("zcRefTypeSetup" "Type" t)
    '("zcLanguageSetup" "Language" t))
   (when (and (featurep 'font-latex)
              (eq TeX-install-font-lock 'font-latex-setup))
     (font-latex-add-keywords '(("zcref" "[{")
                                ("zcpageref" "[{"))
                              'reference)))
 TeX-dialect)
;;; zref-clever.el ends here
