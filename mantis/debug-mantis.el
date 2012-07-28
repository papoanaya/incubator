;; This buffer is for notes you don't want to save, and for Lisp evaluation.
;; If you want to create a file, visit that file with C-x C-f,
;; then enter the text in that file's own buffer.

;(mantis-load-wsdl)
;(message (mantis-get-version "papo" "petra1!"))
(setq results (mantis-get-projects "papo" "petra1!"))

(dolist (result-item results)
  (message (cdr (nth 1 result-item) ))
)

