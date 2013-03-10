;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; MODULE      : init-pari.scm
;; DESCRIPTION : Initialize tclsh plugin
;; COPYRIGHT   : (C) 2004  Ero Carrera,
;;               (C) 2012  Adrian Soto
;;
;; This software falls under the GNU general public license version 3 or later.
;; It comes WITHOUT ANY WARRANTY WHATSOEVER. For details, see the file LICENSE
;; in the root directory or <http://www.gnu.org/licenses/gpl-3.0.html>.
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;Basically, the serializer makes the input preserve the newlines
;;and adds the string character "\n<EOF>\n" by the end.
;;I guess it could send "\x04" instead to signal a real EOF,
;;but I would need to check if that does not kill the pipe...
;;An alternative approach is to use the input-done? command
;;from TeXmacs, but, at the time of this writing, it did not work.--A

(define (mathomatic-serialize lan t)
  (import-from (utils plugins plugin-cmd))
  (with u (pre-serialize lan t)
    (with s (texmacs->verbatim (stree->tree u))
      (string-append  s  "\n"))))

;;  (:require (url-exists-in-path? "tm_tclsh"))
;;  (:launch "tm_tclsh --texmacs")
;;  (:require (url-exists-in-path? "tclsh"))
;;  (:serializer ,tclsh-serialize)
;;  (:tab-completion #t)

(plugin-configure tclsh
  (:require (url-exists-in-path? "mathomatic"))
  (:launch "gomathomatic.nlsp")
  (:session "Mathomatic"))
