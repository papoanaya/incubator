;;; ob-newlisp.el --- org-babel functions for newlisp evaluation

;; Copyright (C) 2010-2012  Free Software Foundation, Inc.

;; Authors: Thorsten Jolitz
;;	 Eric Schulte
;;   Luis Anaya (newlisp)
;; Keywords: literate programming, reproducible research
;; Homepage: http://orgmode.org

;; This file is part of GNU Emacs.

;; GNU Emacs is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; GNU Emacs is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; This library enables the use of Newlisp in the multi-language
;; programming framework Org-Babel.

;;; Requirements:

;;; Code:
(require 'ob)
(require 'ob-eval)
(require 'ob-comint)
(require 'comint)
(eval-when-compile (require 'cl))

(declare-function run-newlisp "ext:inferior-newlisp" (cmd))

;; optionally define a file extension for this language
(add-to-list 'org-babel-tangle-lang-exts '("newlisp" . "lsp"))

;;; interferes with settings in org-babel buffer?
;; optionally declare default header arguments for this language
;; (defvar org-babel-default-header-args:newlisp
;;   '((:colnames . "no"))
;;   "Default arguments for evaluating a newlisp source block.")

(defvar org-babel-newlisp-eoe "org-babel-newlisp-eoe"
  "String to indicate that evaluation has completed.")

(defcustom org-babel-newlisp-cmd "newlisp"
  "Name of command used to evaluate newlisp blocks."
  :group 'org-babel
  :version "24.1"
  :type 'string)

(defun org-babel-expand-body:newlisp (body params &optional processed-params)
  "Expand BODY according to PARAMS, return the expanded body."
  (let ((vars (mapcar #'cdr (org-babel-get-header params :var)))
        (result-params (cdr (assoc :result-params params)))
        (print-level nil) (print-length nil))
    (if (> (length vars) 0)
        (concat "(begin (let ("
                (mapconcat
                 (lambda (var)
                   (format "%S '%S)"
                           (print (car var))
                           (print (cdr var))))
                 vars "\n      ")
                " \n" body ") )")
      body)))

(defun org-babel-execute:newlisp (body params)
  "Execute a block of Newlisp code with org-babel.  This function is
 called by `org-babel-execute-src-block'"
  (message "executing Newlisp source code block")
  (let* (
	 ;; name of the session or "none"
	 (session-name (cdr (assoc :session params)))
	 ;; set the session if the session variable is non-nil
	 (session (org-babel-newlisp-initiate-session session-name))
	 ;; either OUTPUT or VALUE which should behave as described above
	 (result-type (cdr (assoc :result-type params)))
	 (result-params (cdr (assoc :result-params params)))
	 ;; expand the body with `org-babel-expand-body:newlisp'
	 (full-body (org-babel-expand-body:newlisp body params))
         ;; wrap body appropriately for the type of evaluation and results
         (wrapped-body
          (cond
           ((or (member "code" result-params)
                (member "pp" result-params))
            (format "(write-file \"/dev/null\" %s)" full-body))
           ((and (member "value" result-params) (not session))
            (format "(write-file \"/dev/null\" %s)" full-body))
           ((member "value" result-params)
            (format "(write-file \"/dev/null\" %s)" full-body))
           (t full-body))))

    ((lambda (result)
       (if (or (member "verbatim" result-params)
               (member "scalar" result-params)
               (member "output" result-params)
               (member "code" result-params)
               (member "pp" result-params)
               (= (length result) 0))
           result
         (read result)))
     (if (not (string= session-name "none"))
         ;; session based evaluation
	 (mapconcat ;; <- joins the list back together into a single string
          #'identity
          (butlast ;; <- remove the org-babel-newlisp-eoe line
           (delq nil
                 (mapcar
                  (lambda (line)
                    (org-babel-chomp ;; remove trailing newlines
                     (when (> (length line) 0) ;; remove empty lines
		       (cond
			;; remove leading "> " from return values
			((and (>= (length line) 2)
			      (string= "> " (substring line 0 2)))
			 (substring line 3))
			;; remove trailing "> <<return-value>>" on the
			;; last line of output
			((and (member "output" result-params)
			      (string-match-p ">" line))
			 (substring line 0 (string-match ">" line)))
			(t line)
			)
                       ;; (if (and (>= (length line) 3) ;; remove leading "<- "
                       ;;          (string= "-> " (substring line 0 3)))
                       ;;     (substring line 3)
                       ;;   line)
		       )))
                  ;; returns a list of the output of each evaluated expression
                  (org-babel-comint-with-output (session org-babel-newlisp-eoe)
                    (insert wrapped-body) (comint-send-input)
                    (insert "'" org-babel-newlisp-eoe) (comint-send-input)))))
          "\n")
       ;; external evaluation
       (let ((script-file (org-babel-temp-file "newlisp-script-")))
	 (with-temp-file script-file
	   (insert (concat wrapped-body "(exit)")))
         (org-babel-eval
          (format "%s %s"
                  org-babel-newlisp-cmd
                  (org-babel-process-file-name script-file))
          ""))))))

(defun org-babel-newlisp-initiate-session (&optional session-name)
  "If there is not a current inferior-process-buffer in SESSION
then create.  Return the initialized session."
  (unless (string= session-name "none")
    ; (require 'inferior-newlisp)
    (newlisp-show-interpreter)
    ;; provide a reasonable default session name
    (let ((session (or session-name "*newlisp*")))
      ;; check if we already have a live session by this name
      (if (org-babel-comint-buffer-livep session)
          (get-buffer session)
        (save-window-excursion
          (run-newlisp org-babel-newlisp-cmd)
          (rename-buffer session-name)
          (current-buffer))))))

(provide 'ob-newlisp)



;;; ob-newlisp.el ends here
