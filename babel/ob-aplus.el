;;; ob-aplus.el --- org-babel functions for aplus evaluation

;; Copyright (C) 2010-2012  Free Software Foundation, Inc.

;; Authors: Thorsten Jolitz
;;	 Eric Schulte
;;   Luis Anaya (aplus)
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

;; This library enables the use of aplus in the multi-language
;; programming framework Org-Babel. 

;;; Requirements:

;;; Code:
(require 'ob)
(require 'ob-eval)
(require 'ob-comint)
(require 'comint)
(eval-when-compile (require 'cl))

(declare-function run-aplus "ext:inferior-aplus" (cmd))

;; optionally define a file extension for this language
(add-to-list 'org-babel-tangle-lang-exts '("aplus" . "a+"))

;;; interferes with settings in org-babel buffer?
;; optionally declare default header arguments for this language
;; (defvar org-babel-default-header-args:aplus
;;   '((:colnames . "no"))
;;   "Default arguments for evaluating a aplus source block.")

(defvar org-babel-aplus-eoe "org-babel-aplus-eoe"
  "String to indicate that evaluation has completed.")

(defcustom org-babel-aplus-cmd "a+"
  "Name of command used to evaluate aplus blocks."
  :group 'org-babel
  :version "24.1"
  :type 'string)


(defun org-babel-execute:aplus (body params)
  "Execute a block of aplus code with org-babel.  This function is
 called by `org-babel-execute-src-block'"
  (message "executing aplus source code block")
  (let* (
	 ;; name of the session or "none"
	 (session-name (cdr (assoc :session params)))
	 ;; set the session if the session variable is non-nil
	 (session (org-babel-aplus-initiate-session session-name))
	 ;; either OUTPUT or VALUE which should behave as described above
	 (result-type (cdr (assoc :result-type params)))
	 (result-params (cdr (assoc :result-params params)))
	 ;; expand the body with `org-babel-expand-body:aplus'
;;	 (full-body (org-babel-expand-body:aplus body params))
         ;; wrap body appropriately for the type of evaluation and results
     (wrapped-body body))

    ((lambda (result)
       (if (or (member "verbatim" result-params)
               (member "scalar" result-params)
               (member "output" result-params)
               (member "code" result-params)
               (= (length result) 0))
           result
         (read result)))
     (if (not (string= session-name "none"))
         ;; session based evaluation
	 (mapconcat ;; <- joins the list back together into a single string
          #'identity
          (butlast ;; <- remove the org-babel-aplus-eoe line
           (delq nil
                 (mapcar
                  (lambda (line)
                    (org-babel-chomp ;; remove trailing newlines
                     (when (> (length line) 0) ;; remove empty lines
                       
                       line)))
                  ;; returns a list of the output of each evaluated expression
                  (org-babel-comint-with-output (session org-babel-aplus-eoe)
                    (insert wrapped-body) (comint-send-input)
                    (insert "'" org-babel-aplus-eoe) (comint-send-input)))))
          "\n")
       ;; external evaluation
       (let ((script-file (org-babel-temp-file "aplus-script-")))
	 (with-temp-file script-file
	   (insert (concat "$mode ascii\n" wrapped-body "\n$off\n")))
         (org-babel-eval
          (format "%s %s"
                  org-babel-aplus-cmd
                  (org-babel-process-file-name script-file))
          ""))))))

(defun org-babel-aplus-initiate-session (&optional session-name)
  "If there is not a current inferior-process-buffer in SESSION
then create.  Return the initialized session."
  (unless (string= session-name "none")
    ; (require 'inferior-aplus)
    (aplus-show-interpreter)
    ;; provide a reasonable default session name
    (let ((session (or session-name "*aplus*")))
      ;; check if we already have a live session by this name
      (if (org-babel-comint-buffer-livep session)
          (get-buffer session)
        (save-window-excursion
          (run-aplus org-babel-aplus-cmd)
          (rename-buffer session-name)
          (current-buffer))))))

(provide 'ob-aplus)



;;; ob-aplus.el ends here
