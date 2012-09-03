;;; ob-jlang.el --- org-babel functions for jlang evaluation

;; Copyright (C) 2010-2012  Free Software Foundation, Inc.

;; Authors: Thorsten Jolitz
;;	 Eric Schulte
;;   Luis Anaya (J Language)
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

;; This library enables the use of Jlang in the multi-language
;; programming framework Org-Babel. 

;;; Requirements:

;;; Code:
(require 'ob)
(require 'ob-eval)
(require 'ob-comint)
(require 'comint)
(eval-when-compile (require 'cl))

(declare-function run-jlang "ext:inferior-jlang" (cmd))

;; optionally define a file extension for this language
(add-to-list 'org-babel-tangle-lang-exts '("jlang" . "ijs"))

;;; interferes with settings in org-babel buffer?
;; optionally declare default header arguments for this language
;; (defvar org-babel-default-header-args:jlang
;;   '((:colnames . "no"))
;;   "Default arguments for evaluating a jlang source block.")

(defvar org-babel-jlang-eoe "org-babel-jlang-eoe"
  "String to indicate that evaluation has completed.")

(defcustom org-babel-jlang-cmd "jconsole"
  "Name of command used to evaluate jlang blocks."
  :group 'org-babel
  :version "24.1"
  :type 'string)


(defun org-babel-execute:jlang (body params)
  "Execute a block of Jlang code with org-babel.  This function is
 called by `org-babel-execute-src-block'"
  (message "executing Jlang source code block")
  (let* (
	 ;; name of the session or "none"
	 (session-name (cdr (assoc :session params)))
	 ;; set the session if the session variable is non-nil
	 (session (org-babel-jlang-initiate-session session-name))
	 ;; either OUTPUT or VALUE which should behave as described above
	 (result-type (cdr (assoc :result-type params)))
	 (result-params (cdr (assoc :result-params params)))
	 ;; expand the body with `org-babel-expand-body:jlang'
	 ;;(full-body (org-babel-expand-body:jlang body params))
         ;; wrap body appropriately for the type of evaluation and results
     (wrapped-body body))

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
          (butlast ;; <- remove the org-babel-jlang-eoe line
           (delq nil
                 (mapcar
                  (lambda (line)
                    (org-babel-chomp ;; remove trailing newlines
                     (when (> (length line) 0) ;; remove empty lines
                       
                       line)))
                  ;; returns a list of the output of each evaluated expression
                  (org-babel-comint-with-output (session org-babel-jlang-eoe)
                    (insert wrapped-body) (comint-send-input)
                    (insert "'" org-babel-jlang-eoe) (comint-send-input)))))
          "\n")
       ;; external evaluation
       (let ((script-file (org-babel-temp-file "jlang-script-")))
	 (with-temp-file script-file
	   (insert (concat wrapped-body "\n2!:55 '0'\n")))
         (org-babel-eval
          (format "%s %s"
                  org-babel-jlang-cmd
                  (org-babel-process-file-name script-file))
          ""))))))

(defun org-babel-jlang-initiate-session (&optional session-name)
  "If there is not a current inferior-process-buffer in SESSION
then create.  Return the initialized session."
  (unless (string= session-name "none")
    ; (require 'inferior-jlang)
    (jlang-show-interpreter)
    ;; provide a reasonable default session name
    (let ((session (or session-name "*jlang*")))
      ;; check if we already have a live session by this name
      (if (org-babel-comint-buffer-livep session)
          (get-buffer session)
        (save-window-excursion
          (run-jlang org-babel-jlang-cmd)
          (rename-buffer session-name)
          (current-buffer))))))

(provide 'ob-jlang)



;;; ob-jlang.el ends here
